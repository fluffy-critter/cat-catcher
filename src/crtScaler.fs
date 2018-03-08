/* crtScaler.fs

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.

Integrals computed using https://www.integral-calculator.com
*/

uniform vec2 screenSize;
uniform vec2 outputSize;

// TODO - sin(x1)-sin(x0) probably has a simpler form when x1-x0 is constant
// TODO - this could also be approximated with a polynomial form of e.g. fract(2*pi*x) although I suspect most modern GPUs do that already

float xbrt(float x0, float x1) {
    // integral of .05*sin(x) + .95 = (19x-cos(x))/20
    return sqrt(4.0/5.0 + (cos(x0) - cos(x1))/5.0/(x1 - x0));
}

float ybrt(float x0, float x1) {
    // integral of (1-cos(x))/2 = (x-sin(x))/2
    return sqrt(0.5 + (sin(x0) - sin(x1))/2.0/(x1 - x0));
}

vec4 effect(vec4 color, Image txt, vec2 itc, vec2 screen_coords) {
    /* TODO: crt bulge

    on lower-resolution screens (i.e. 1080p or lower) we end up causing aliasing especially towards the edges; we need to fix that
    somehow

    possibilities:
    - sample neighboring rows and filter ourselves
    - render screen to undistorted canvas and have separate distort shader
    - just get rid of distortion since it's not really noticeable except for how it goes wrong anyway and flat tubes
      were totally a thing in the 90s
    */
    //vec2 tc = vec2((itc.x - 0.5)*(itc.y*(itc.y - 1)*0.02 + 1.0) + 0.5,
    //               (itc.y - 0.5)*(itc.x*(itc.x - 1)*0.05 + 1.0) + 0.5);
    vec2 tc = itc;


    // typical 14" 90s CRT was 1152 dots wide on the shadow mask; we cut this a
    // bunch because that means it's very subtle even at 4K
    const float hPitch = 1152.0/2.0;
    // const float hPitch = 5;

    float dot = tc.x*hPitch;

    // phase of the left extent of the dot
    float phaseL = dot*3.14159*2;

    // phase of the right extent of the dot
    float phaseR = (tc.x + 1.0/outputSize.x)*hPitch*3.14159*2;

    vec3 maskColor = vec3(xbrt(phaseL, phaseR),
        xbrt(phaseL - 2.09, phaseR - 2.09),
        xbrt(phaseL + 2.09, phaseR + 2.09));

    // TODO: dot mask vertical pattern
    // typical dot mask had a typical aperture aspect of 9:7, meaning 1152*3/4*7/9 = 672 dots tall
    // vertical 'duty cycle' is about 85%, with an offset every other column

    // CRT scanlines
    float rowT = tc.y*screenSize.y;
    float rowB = (tc.y + 1.0/outputSize.y)*screenSize.y;
    float beamColor = ybrt(rowT*2*3.14159, rowB*2*3.14159)*.5 + .75;

    // simulate a little horizontal smearing
    vec2 pixelSoft = vec2(tc.x, (floor(rowT) + 0.5)/screenSize.y);
    vec2 pixelHard = vec2((floor(tc.x*screenSize.x) + 0.5)/screenSize.x, pixelSoft.y);
    float xofs = fract(tc.x*screenSize.x);
    float blend = 4.0*xofs*(1.0 - xofs);
    vec4 pixelColor = blend*Texel(txt, pixelHard) + (1.0 - blend)*Texel(txt, pixelSoft);

    return color * vec4(pixelColor.rgb * maskColor * beamColor, 1.0);
}
