This pack contains a few shaders to create refractive Glass-like Materials.

Glass-like because the effect is a distortion based on surface Normal but not based
on a physical model of refraction!

To use a RefractionSurface shader
simply create a material and assign any of the shaders under "Refractive/" to it.

There are a few options to optimise GPU load:
	LOW    : "Refractive/RefractSurf_noGloss_noMaps"
	MEDIUM : "Refractive/RefractSurf_noGloss"
	HIGH   : "Refractive/RefractSurf_full"
	
Keep in mind that these shaders make use of GrabPass to get texture of the scene behind
rendered object. So use it wisely!

for any questions write to: artkalev@gmail.com