//
//  CVImageConverter.m
//
//  Created by Artem Myagkov on 01.08.11.
/*
 *
 *
 Copyright (c) 2011, Artem Myagkov
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the 
 documentation and/or other materials provided with the distribution.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 *
 */

#import "CVImageConverter.h"
#include <math.h>
static inline double radians (double degrees) {return degrees * M_PI/180;}

@implementation CVImageConverter

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

+ (UIImage *)UIImageFromCVMat:(const cv::Mat&)cv_image error:(NSError **)outError {
    
    int width = cv_image.cols, height = cv_image.rows;
    int _channels = cv_image.channels();
    const uchar* data = cv_image.data;
    int step = cv_image.step;
    
    // Determine the Bytes Per Pixel
    int bpp = (_channels == 1) ? 1 : 4;
    
    // Write the data into a bitmap context
    CGContextRef context;
    CGColorSpaceRef colorSpace;
    uchar* bitmapData = NULL;
    
    if( bpp == 1 ) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    }
    else if( bpp == 4 ) {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    if( !colorSpace ) {
        if (outError != NULL) {
            // Create error object
            // TO DO: Create error with normal description, that makes sense
            // (now returns "Operation not supported by device")
            *outError = [[[NSError alloc] initWithDomain:NSPOSIXErrorDomain 
                                                    code:19 
                                                userInfo:nil] autorelease];         
        }
        return nil;
    }
    
    bitmapData = (uchar*)malloc( bpp * height * width );
    if( !bitmapData )
    {
        CGColorSpaceRelease( colorSpace );
        if (outError != NULL) {
            // Create error object
            // Returns "Cannot allocate memory"
            *outError = [[[NSError alloc] initWithDomain:NSPOSIXErrorDomain 
                                                    code:12 
                                                userInfo:nil] autorelease];         
        }
        return nil;
    }
    
    
    context = CGBitmapContextCreate( bitmapData, width, height, 8, bpp * width, colorSpace, (bpp == 1) ? kCGImageAlphaNone : kCGImageAlphaNoneSkipLast );
    
    CGColorSpaceRelease( colorSpace );
    
    if( !context )
    {
        free( bitmapData );
        if (outError != NULL) {
            // Create error object
            // Returns "Cannot allocate memory"
            *outError = [[[NSError alloc] initWithDomain:NSPOSIXErrorDomain 
                                                    code:12 
                                                userInfo:nil] autorelease];         
        }
        return nil;
    }
    
    // Copy pixel information from data into bitmapData
    if (bpp == 4)
    {
        int           bitmapIndex = 0;
		const uchar * base        = data;
        
		for (int y = 0; y < height; y++)
		{
			const uchar * line = base + y * step;
            
		    for (int x = 0; x < width; x++)
		    {
				// Blue channel
                bitmapData[bitmapIndex + 2] = line[0];
				// Green channel
				bitmapData[bitmapIndex + 1] = line[1];
				// Red channel
				bitmapData[bitmapIndex + 0] = line[2];
                
				line        += 3;
				bitmapIndex += bpp;
			}
		}
    }
    else if (bpp == 1)
    {
		for (int y = 0; y < height; y++)
			memcpy (bitmapData + y * width, data + y * step, width);
    }
    
    // Turn the bitmap context into an imageRef
    CGImageRef imageRef = CGBitmapContextCreateImage( context );
    CGContextRelease( context );
    if( !imageRef )
    {
        free( bitmapData );
        if (outError != NULL) {
            // Create error object
            // Returns "Cannot allocate memory"
            *outError = [[[NSError alloc] initWithDomain:NSPOSIXErrorDomain 
                                                    code:12 
                                                userInfo:nil] autorelease];         
        }
        return nil;
    }
    
    UIImage* image = [[UIImage alloc] initWithCGImage:imageRef]; 
    
    if (image == nil) {
        [image release];
        
        CGImageRelease( imageRef );
        free( bitmapData );
        return nil;
    }
    
    
    
    
    
    
    CGImageRelease( imageRef );
    free( bitmapData );
    
    return [image autorelease];
    
}

+ (void)  CVMat:(cv::Mat&)cv_image FromUIImage:(UIImage *)ui_image error:(NSError **)outError {
   
    
    // Get Height, Width, and color information
  
    CGImageRef imageRef = ui_image.CGImage;    
    int m_width = CGImageGetWidth( imageRef );
    int m_height = CGImageGetHeight( imageRef );
    
    CGColorSpaceRef colorSpace = CGImageGetColorSpace( imageRef );
    if( !colorSpace )
        return;
    
    int m_type = CGColorSpaceGetNumberOfComponents( colorSpace ) > 1 ? CV_8UC3 : CV_8UC1;
    
        
    cv::Mat img = cv::Mat( m_height, m_width, m_type);
    uchar* data = img.data;
    int step = img.step;
    //bool color = img.channels() > 1;
    int bpp; // Bytes per pixel
    int bit_depth = 8;

    
    CGContextRef     context = NULL; // The bitmap context
    colorSpace = NULL;
    uchar*           bitmap = NULL;
    CGImageAlphaInfo alphaInfo;
    
    // CoreGraphics will take care of converting to grayscale and back as long as the
    // appropriate colorspace is set
    if( m_type == CV_8UC1 )
    {
        colorSpace = CGColorSpaceCreateDeviceGray();
        bpp = 1;
        alphaInfo = kCGImageAlphaNone;
    }
    else if( m_type == CV_8UC3 )
    {
        colorSpace = CGColorSpaceCreateDeviceRGB();
        bpp = 4; /* CG only has 8 and 32 bit color spaces, so we waste a byte */
        alphaInfo = kCGImageAlphaNoneSkipLast;
    }
    
    if( !colorSpace ) {
        if (outError != NULL) {
            // Create error object
            // TO DO: Create error with normal description, that makes sense
            // (now returns "Operation not supported by device")
            *outError = [[[NSError alloc] initWithDomain:NSPOSIXErrorDomain 
                                                    code:19 
                                                userInfo:nil] autorelease];         
        }
        return;
    }
    
    bitmap = (uchar*)malloc( bpp * m_height * m_width );
    if( !bitmap )
    {
        CGColorSpaceRelease( colorSpace );
        return;
    }
    
    context = CGBitmapContextCreate( (void *)bitmap,
                                    m_width,        /* width */
                                    m_height,       /* height */
                                    bit_depth,    /* bit depth */
                                    bpp * m_width,  /* bytes per row */
                                    colorSpace,     /* color space */
                                    alphaInfo);
    
    CGColorSpaceRelease( colorSpace );
    if( !context )
    {
        free( bitmap );
        return;
    }
    CGRect rect = {{0,0},{static_cast<CGFloat>(m_width),static_cast<CGFloat>(m_height)}};
    // Flip the context so that the PDF page is rendered right side up
    //CGContextTranslateCTM(context, 0.0, ui_image.size.height);
    //CGContextScaleCTM(context, -1.0, 1.0);
    //CGContextRotateCTM(context, 90.0);
    
    // Copy the image data into the bitmap region
    
    CGContextDrawImage( context, rect, imageRef );
    //CGContextScaleCTM(context, -1.0, 1.0);
    
    uchar* bitdata = (uchar*)CGBitmapContextGetData( context );
    if( !bitdata )
    {
        free( bitmap);
        CGContextRelease( context );
        return;
    }
    
    // Move the bitmap (in RGB) into data (in BGR)
    int bitmapIndex = 0;
    
    if( m_type == CV_8UC3 )
	{
		uchar* base = data;
        
		for (int y = 0; y < m_height; y++)
		{
			uchar * line = base + y * step;
            
		    for (int x = 0; x < m_width; x++)
		    {
				// Blue channel
				line[0] = bitdata[bitmapIndex + 2];
				// Green channel
				line[1] = bitdata[bitmapIndex + 1];
				// Red channel
				line[2] = bitdata[bitmapIndex + 0];
                
				line        += 3;
				bitmapIndex += bpp;
			}
		}
    }
    else if( m_type == CV_8UC1 )
    {
		for (int y = 0; y < m_height; y++)
			memcpy (data + y * step, bitmap + y * m_width, m_width);
    }
    
    free( bitmap );
    CGContextRelease( context );
    
    UIImageOrientation orient = ui_image.imageOrientation;
    
    if (orient == UIImageOrientationUpMirrored) {
        cv::Mat dst;
        dst.create( img.size(), img.type() );
        cv::Mat map_x, map_y;
        map_x.create( img.size(), CV_32FC1 );
        map_y.create( img.size(), CV_32FC1 );
        
        for( int j = 0; j < img.rows; j++ )
        { 
            for( int i = 0; i < img.cols; i++ )           
            {          
                map_x.at<float>(j,i) = img.cols - i ;
                map_y.at<float>(j,i) = j ;     
            }
        }
        cv::remap( img, dst, map_x, map_y, CV_INTER_LINEAR, cv::BORDER_CONSTANT, cv::Scalar(0,0, 0) );        
        dst.copyTo(cv_image);
        return;
    }
    
    if (orient != UIImageOrientationUp) {        
       
        
        cv::Mat rot_mat( 2, 3, CV_32FC1 );
        cv::Mat warp_dst;
        
        cv::Point center = cv::Point( img.cols/2, img.rows/2 );
        double angle = -90.0;
        if (orient ==  UIImageOrientationRight) {
            angle = 90.0;
        }
        double scale = 1.0;
        
        rot_mat = cv::getRotationMatrix2D(center, angle, scale);
        cv::warpAffine( img, warp_dst, rot_mat, img.size() );
        cv::transpose(img, warp_dst);
        
        if (orient == UIImageOrientationLeft || orient == UIImageOrientationRight) {
            cv::Mat dst;
            dst.create( warp_dst.size(), warp_dst.type() );
            cv::Mat map_x, map_y;
            map_x.create( warp_dst.size(), CV_32FC1 );
            map_y.create( warp_dst.size(), CV_32FC1 );
            
            for( int j = 0; j < warp_dst.rows; j++ )
            { 
                for( int i = 0; i < warp_dst.cols; i++ )           
                {          
                    map_x.at<float>(j,i) = warp_dst.cols - i ;
                    map_y.at<float>(j,i) = j ;     
                }
            }
            cv::remap( warp_dst, dst, map_x, map_y, CV_INTER_LINEAR, cv::BORDER_CONSTANT, cv::Scalar(0,0, 0) );            
            dst.copyTo(cv_image);
            return;
        }        
        warp_dst.copyTo(cv_image);
        return;
        
    }
    
    img.copyTo(cv_image);    
    return;
}

+ (void)CVMat:(cv::Mat &)cv_image FromCGImageRef:(CGImageRef)imageRef withOrientation:(ALAssetOrientation)orientation error:(NSError **)outError {
        
      
    int m_width = CGImageGetWidth( imageRef );
    int m_height = CGImageGetHeight( imageRef );
    
    CGColorSpaceRef colorSpace = CGImageGetColorSpace( imageRef );
    if( !colorSpace )
        return;
    
    int m_type = CGColorSpaceGetNumberOfComponents( colorSpace ) > 1 ? CV_8UC3 : CV_8UC1;
    
    
    cv::Mat img = cv::Mat( m_height, m_width, m_type);
    uchar* data = img.data;
    int step = img.step;
    //bool color = img.channels() > 1;
    int bpp; // Bytes per pixel
    int bit_depth = 8;
    
    
    CGContextRef     context = NULL; // The bitmap context
    colorSpace = NULL;
    uchar*           bitmap = NULL;
    CGImageAlphaInfo alphaInfo;
    
    // CoreGraphics will take care of converting to grayscale and back as long as the
    // appropriate colorspace is set
    if( m_type == CV_8UC1 )
    {
        colorSpace = CGColorSpaceCreateDeviceGray();
        bpp = 1;
        alphaInfo = kCGImageAlphaNone;
    }
    else if( m_type == CV_8UC3 )
    {
        colorSpace = CGColorSpaceCreateDeviceRGB();
        bpp = 4; /* CG only has 8 and 32 bit color spaces, so we waste a byte */
        alphaInfo = kCGImageAlphaNoneSkipLast;
    }
    
    if( !colorSpace ) {
        if (outError != NULL) {
            // Create error object
            // TO DO: Create error with normal description, that makes sense
            // (now returns "Operation not supported by device")
            *outError = [[[NSError alloc] initWithDomain:NSPOSIXErrorDomain 
                                                    code:19 
                                                userInfo:nil] autorelease];         
        }
        return;
    }
    
    bitmap = (uchar*)malloc( bpp * m_height * m_width );
    if( !bitmap )
    {
        CGColorSpaceRelease( colorSpace );
        return;
    }
    
    context = CGBitmapContextCreate( (void *)bitmap,
                                    m_width,        /* width */
                                    m_height,       /* height */
                                    bit_depth,    /* bit depth */
                                    bpp * m_width,  /* bytes per row */
                                    colorSpace,     /* color space */
                                    alphaInfo);
    
    CGColorSpaceRelease( colorSpace );
    if( !context )
    {
        free( bitmap );
        return;
    }
    CGRect rect = {{0,0},{static_cast<CGFloat>(m_width),static_cast<CGFloat>(m_height)}};
    // Flip the context so that the PDF page is rendered right side up
    //CGContextTranslateCTM(context, 0.0, ui_image.size.height);
    //CGContextScaleCTM(context, -1.0, 1.0);
    //CGContextRotateCTM(context, 90.0);
    
    // Copy the image data into the bitmap region
    
    CGContextDrawImage( context, rect, imageRef );
    //CGContextScaleCTM(context, -1.0, 1.0);
    
    uchar* bitdata = (uchar*)CGBitmapContextGetData( context );
    if( !bitdata )
    {
        free( bitmap);
        CGContextRelease( context );
        return;
    }
    
    // Move the bitmap (in RGB) into data (in BGR)
    int bitmapIndex = 0;
    
    if( m_type == CV_8UC3 )
	{
		uchar* base = data;
        
		for (int y = 0; y < m_height; y++)
		{
			uchar * line = base + y * step;
            
		    for (int x = 0; x < m_width; x++)
		    {
				// Blue channel
				line[0] = bitdata[bitmapIndex + 2];
				// Green channel
				line[1] = bitdata[bitmapIndex + 1];
				// Red channel
				line[2] = bitdata[bitmapIndex + 0];
                
				line        += 3;
				bitmapIndex += bpp;
			}
		}
    }
    else if( m_type == CV_8UC1 )
    {
		for (int y = 0; y < m_height; y++)
			memcpy (data + y * step, bitmap + y * m_width, m_width);
    }
    
    free( bitmap );
    CGContextRelease( context );
    
  
    
    if (orientation == ALAssetOrientationUpMirrored) {
        cv::Mat dst;
        dst.create( img.size(), img.type() );
        cv::Mat map_x, map_y;
        map_x.create( img.size(), CV_32FC1 );
        map_y.create( img.size(), CV_32FC1 );
        
        for( int j = 0; j < img.rows; j++ )
        { 
            for( int i = 0; i < img.cols; i++ )           
            {          
                map_x.at<float>(j,i) = img.cols - i ;
                map_y.at<float>(j,i) = j ;     
            }
        }
        cv::remap( img, dst, map_x, map_y, CV_INTER_LINEAR, cv::BORDER_CONSTANT, cv::Scalar(0,0, 0) );        
        dst.copyTo(cv_image);
        return;
    }
    
    if (orientation != ALAssetOrientationUp) {        
        
        
        cv::Mat rot_mat( 2, 3, CV_32FC1 );
        cv::Mat warp_dst;
        
        cv::Point center = cv::Point( img.cols/2, img.rows/2 );
        double angle = -90.0;
        if (orientation ==  ALAssetOrientationRight) {
            angle = 90.0;
        }
        double scale = 1.0;
        
        rot_mat = cv::getRotationMatrix2D(center, angle, scale);
        cv::warpAffine( img, warp_dst, rot_mat, img.size() );
        cv::transpose(img, warp_dst);
        
        if (orientation == ALAssetOrientationLeft || orientation == ALAssetOrientationRight) {
            cv::Mat dst;
            dst.create( warp_dst.size(), warp_dst.type() );
            cv::Mat map_x, map_y;
            map_x.create( warp_dst.size(), CV_32FC1 );
            map_y.create( warp_dst.size(), CV_32FC1 );
            
            for( int j = 0; j < warp_dst.rows; j++ )
            { 
                for( int i = 0; i < warp_dst.cols; i++ )           
                {          
                    map_x.at<float>(j,i) = warp_dst.cols - i ;
                    map_y.at<float>(j,i) = j ;     
                }
            }
            cv::remap( warp_dst, dst, map_x, map_y, CV_INTER_LINEAR, cv::BORDER_CONSTANT, cv::Scalar(0,0, 0) );            
            dst.copyTo(cv_image);
            return;
        }        
        warp_dst.copyTo(cv_image);
        return;
        
    }
    
    img.copyTo(cv_image);    
    return;

    
}

@end
