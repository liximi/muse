uniform vec2 center;       // 圆角矩形中心（窗口坐标，如 (400, 300)）
uniform vec2 halfSize;     // 圆角矩形半尺寸（宽/2, 高/2，如 (100,50)→实际200x100）
uniform float sigma;       // 阴影模糊半径（2~20 为宜）
uniform float corner;      // 圆角半径（0=方形，最大不超过 min(halfSize.x, halfSize.y)）
uniform vec2 shadowOffset; // 阴影偏移（x右移，y下移，如 (8,8)）
uniform vec4 shadowColor;  // 阴影颜色（RGBA，如 (0,0,0,0.5)→半透黑）
// 1. 误差函数（erf）近似
vec2 erf(vec2 x) {
	vec2 s = sign(x);
	vec2 a = abs(x);
	x = 1.0 + (0.278393 + (0.230389 + 0.078108 * (a * a)) * a) * a;
	x *= x;
	return s - s / (x * x);
}
// 2. 高斯函数
float gaussian(float x, float sigma) {
	const float pi = 3.141592653589793;
	return exp(-(x * x) / (2.0 * sigma * sigma)) / (sqrt(2.0 * pi) * sigma);
}
// 3. x方向闭式解
float roundedBoxShadowX(float x, float y, float sigma, float corner, vec2 halfSize) {
	float delta = min(halfSize.y - corner - abs(y), 0.0);
	float curvedX = halfSize.x - corner + sqrt(max(0.0, corner * corner - delta * delta));
	vec2 integral = 0.5 + 0.5 * erf((x + vec2(-curvedX, curvedX)) * (sqrt(0.5) / sigma));
	return integral.y - integral.x;
}
// 4. 圆角阴影主函数
float roundedBoxShadow(vec2 point, vec2 halfSize, float sigma, float corner) {
	float safeSigma = max(sigma, 0.1); // 避免 sigma=0 导致计算错误
	float safeCorner = clamp(corner, 0.0, min(halfSize.x, halfSize.y)); // 限制圆角最大范围

	// 确定 y 方向采样范围（高斯 3σ 外贡献 <0.3%，无需采样）
	float lowY = point.y - halfSize.y;
	float highY = point.y + halfSize.y;
	float sampleStart = clamp(-3.0 * safeSigma, lowY, highY);
	float sampleEnd = clamp(3.0 * safeSigma, lowY, highY);

	// 4点采样（平衡精度与性能）
	float sampleStep = (sampleEnd - sampleStart) / 4.0;
	float ySample = sampleStart + sampleStep * 0.5;
	float shadowIntensity = 0.0;

	for (int i = 0; i < 4; i++) {
		shadowIntensity += roundedBoxShadowX(point.x, point.y - ySample, safeSigma, safeCorner, halfSize)
						* gaussian(ySample, safeSigma)
						* sampleStep;
		ySample += sampleStep;
	}

	return clamp(shadowIntensity, 0.0, 1.0);
}
// 片元着色器入口函数
// - color：顶点传递的颜色
// - texture：当前绑定的纹理（此处不用，忽略）
// - texcoord：纹理坐标（此处不用，忽略）
// - pixcoord：当前像素的窗口坐标（左上角为原点）
vec4 effect(vec4 color, Image texture, vec2 texcoord, vec2 pixcoord) {
	// 计算阴影位置 = 像素坐标 - 阴影偏移（阴影在原矩形的偏移方向）
	vec2 shadowPos = pixcoord - shadowOffset;
	// 转换为“相对于矩形中心的坐标”（算法要求的中心化坐标）
	vec2 point = shadowPos - center;
	// 计算阴影强度，叠加颜色
	float intensity = roundedBoxShadow(point, halfSize, sigma, corner);
	return intensity * shadowColor * color;
}