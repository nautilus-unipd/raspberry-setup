"""
Stub implementation of pykms to allow picamera2 to import without DRM functionality.
This provides minimal compatibility for environments where full KMS support isn't available.
"""

class PixelFormat:
    """Stub PixelFormat class with common pixel format constants"""
    RGB888 = "RGB888"
    BGR888 = "BGR888"
    XRGB8888 = "XRGB8888"
    XBGR8888 = "XBGR8888"
    ARGB8888 = "ARGB8888"
    ABGR8888 = "ABGR8888"
    RGB565 = "RGB565"
    BGR565 = "BGR565"
    YUV420 = "YUV420"
    YVU420 = "YVU420"
    NV12 = "NV12"
    NV21 = "NV21"
    YUYV = "YUYV"
    YVYU = "YVYU"
    UYVY = "UYVY"
    VYUY = "VYUY"

class DrmConnector:
    def __init__(self, *args, **kwargs):
        pass

class DrmCrtc:
    def __init__(self, *args, **kwargs):
        pass
        
class DrmEncoder:
    def __init__(self, *args, **kwargs):
        pass

class DrmPlane:
    def __init__(self, *args, **kwargs):
        pass

class DrmFramebuffer:
    def __init__(self, *args, **kwargs):
        pass

class Card:
    def __init__(self, *args, **kwargs):
        pass
    
    @property
    def connectors(self):
        return []
    
    @property
    def crtcs(self):
        return []
    
    @property
    def encoders(self):
        return []
    
    @property
    def planes(self):
        return []

# Add any other classes that picamera2 might try to import
__all__ = ['Card', 'DrmConnector', 'DrmCrtc', 'DrmEncoder', 'DrmPlane', 'DrmFramebuffer', 'PixelFormat']
