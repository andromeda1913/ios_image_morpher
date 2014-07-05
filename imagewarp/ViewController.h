//
//  ViewController.h
//  imagewarp
//
//  Created by Igor on 2/9/14.
//  Copyright (c) 2014 Igor. All rights reserved.
//

#import <UIKit/UIKit.h>
#include "imgwarp_mls_rigid.h"
#import "imgwarp_mls_similarity.h"
#import "imgwarp_piecewiseaffine.h"


@interface ViewController : UIViewController

{
    vector<Point_<int>> pointsSrc;
    vector<Point_<int>> pointsDst;
    UIImage *image;
    Mat mat;
    bool warping;
    bool moving;
    ImgWarp_MLS_Rigid imwarp;
}
@property CGPoint currentPoint;
@property int currentPointNum;
@property (nonatomic,retain)IBOutlet UIImageView *imageView;
@property (nonatomic,retain)NSMutableArray *redDots;
@end
