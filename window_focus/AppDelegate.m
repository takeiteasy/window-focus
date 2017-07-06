//
//  AppDelegate.m
//  test_focus
//
//  Created by George Watson on 05/07/2017.
//  Copyright © 2017 George Watson. All rights reserved.
//

#import "AppDelegate.h"
#import "helper.h"

@implementation AppDelegate
-(id)init {
  NSError *error = NULL;
  NSAppleScript* capture_script = LOAD_APPLESCRIPT("capture.scpt");
  
  if (!applescript(capture_script) || access(TMP_BG_LOC, F_OK)) {
    NSLog(@"Failed to take screenshot");
    return nil;
  }
  
  NSScreen *screen = [NSScreen mainScreen];
  CGFloat scale_f = [screen backingScaleFactor];
  NSRect frame = [screen visibleFrame];
  _viewportSize.x = frame.size.width * scale_f;
  _viewportSize.y = (frame.size.height * scale_f) + (4 * scale_f);
  frame.size.height += (4 * scale_f);
  
  _window = [[NSWindow alloc] initWithContentRect:frame
                                        styleMask:NSWindowStyleMaskBorderless
                                          backing:NSBackingStoreBuffered
                                            defer:NO];
  [_window center];
  [_window setTitle: [[NSProcessInfo processInfo] processName]];
  
  _device = MTLCreateSystemDefaultDevice();
  
  MTKView* view = [[MTKView alloc] initWithFrame:frame
                                          device:_device];
  [view setDelegate:self];
  
  view.clearColor = MTLClearColorMake(220.0f / 255.0f, 220.0f / 255.0f, 220.0f / 255.0f, 1.0f);
  
  _commandQueue = [_device newCommandQueue];
  
  Texture* bg = [[Texture alloc] initWithFileAtLocation:TMP_BG_LOC];
  if (!bg) {
    NSLog(@"Failed to create the image from from screenshot!");
    return nil;
  }
  
  MTLTextureDescriptor *textureDescriptor = [[MTLTextureDescriptor alloc] init];
  textureDescriptor.pixelFormat = MTLPixelFormatRGBA8Unorm;
  textureDescriptor.width = bg.width;
  textureDescriptor.height = bg.height;
  
  _texture = [_device newTextureWithDescriptor:textureDescriptor];
  NSUInteger bytesPerRow = bg.chans * bg.width;
  MTLRegion region = {
    {0 ,       0,         0}, // MTLOrigin
    {bg.width, bg.height, 1}  // MTLSize
  };
  
  [_texture replaceRegion:region
              mipmapLevel:0
                withBytes:bg.data.bytes
              bytesPerRow:bytesPerRow];
  
  _vertexBuffer = [_device newBufferWithBytes:quadVertices
                                       length:sizeof(quadVertices)
                                      options:MTLResourceStorageModeShared];
  
  _numVertices = sizeof(quadVertices) / sizeof(AAPLVertex);
  
#ifdef NO_XCODE
  NSString* librarySrc = [NSString stringWithContentsOfFile:@"library.metal"
                                                   encoding:NSUTF8StringEncoding
                                                      error:&error];
  if(!librarySrc) {
    NSLog(@"Failed to read shaders: %@", [error localizedDescription]);
    return nil;
  }
  
  _library = [_device newLibraryWithSource:librarySrc
                                   options:nil
                                     error:&error];
  if(!_library) {
    NSLog(@"Failed to compile shaders: %@", [error localizedDescription]);
    return nil;
  }
#else
  _library = [_device newDefaultLibrary];
#endif
  
  id<MTLFunction> vertexFunction   = [_library newFunctionWithName:@"vertexShader"];
  id<MTLFunction> fragmentFunction = [_library newFunctionWithName:@"samplingShader"];
  
  MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
  pipelineStateDescriptor.label = @"Texturing Pipeline";
  pipelineStateDescriptor.vertexFunction = vertexFunction;
  pipelineStateDescriptor.fragmentFunction = fragmentFunction;
  pipelineStateDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat;
  
  _pipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor
                                                           error:&error];
  if (!_pipelineState) {
    NSLog(@"Failed to created pipeline state, error %@", error);
    return nil;
  }
  
  _pipeline = [_device newComputePipelineStateWithFunction:[_library newFunctionWithName:@"gaussian_blur_2d"]
                                                     error:&error];
  if (!_pipeline) {
    NSLog(@"Faield to create pipeline, error %@", error);
    return nil;
  }
  
  [_window setContentView:view];
  [_window makeKeyAndOrderFront:NSApp];
  
  return self;
}

-(BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication*)theApplication {
  (void)theApplication;
  return YES;
}

-(void)mtkView:(MTKView*)view drawableSizeWillChange:(CGSize)size {
  (void)view;
  (void)size;
}

-(void)drawInMTKView:(MTKView*)view {
  id <MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
  commandBuffer.label = @"MyCommand";
  MTLRenderPassDescriptor *renderPassDescriptor = view.currentRenderPassDescriptor;
  
  if(renderPassDescriptor != nil) {
    id <MTLRenderCommandEncoder> renderEncoder =
    [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
    renderEncoder.label = @"MyRenderEncoder";
    
    [renderEncoder setViewport:(MTLViewport){0.0, 0.0, _viewportSize.x, _viewportSize.y, -1.0, 1.0 }];
    
    [renderEncoder setRenderPipelineState:_pipelineState];
    
    [renderEncoder setVertexBuffer:_vertexBuffer
                            offset:0
                           atIndex:AAPLVertexInputIndexVertices];
    
    [renderEncoder setVertexBytes:&_viewportSize
                           length:sizeof(_viewportSize)
                          atIndex:AAPLVertexInputIndexViewportSize];
    
    [renderEncoder setFragmentTexture:_texture
                              atIndex:AAPLTextureIndexBaseColor];
    
    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle
                      vertexStart:0
                      vertexCount:_numVertices];
    
    [renderEncoder endEncoding];
    [commandBuffer presentDrawable:view.currentDrawable];
  }
  
  [commandBuffer commit];
}

-(void)dealloc {
  int ret = remove(TMP_BG_LOC);
  if (ret != 0)
    NSLog(@"Failed to delete temporary screenshot (%d): \"%s\"", ret, TMP_BG_LOC);
}
@end
