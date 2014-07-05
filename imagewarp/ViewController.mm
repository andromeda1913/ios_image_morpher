//
//  ViewController.m
//  Imagewarp
//  Pashykovdenis@gmail.comv
//  TODO::


//________________________

        //  1  Change Icons :
        //  2  Add One more point ;
        //  3  Set TRansparent  :
        //  4  Add Buttons  Show Hide :

//________________________

//  Created by Igor on 2/9/14.
//  Copyright (c) 2014 Igor. All rights reserved.
//

#import "ViewController.h"
#import "CVImageConverter.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    //loading image
    image=[UIImage imageNamed:@"Mona_Lisa4"];
    
    
    
    CGSize newsize=image.size;
    
    [self.imageView setImage:image];
    
    
    //creating test points
    cv::Point_<int> p1(0+5,0+5),
    p2(newsize.width-1,0+5),
    p3(0+5,newsize.height-1-10),
    p4(newsize.width-1-50,newsize.height-1-10),
    
    p5(newsize.width/4,newsize.height/4),
    p6(newsize.width*3/5,newsize.height/4),
    p7(newsize.width/4,newsize.height*3/5),
    p8(newsize.width*3/5,newsize.height*3/5),
    
    p9(newsize.width*1/5, newsize.height*2/5),
    p10(newsize.width*2/3,newsize.height*2/5) ;
    
    pointsSrc.push_back(p1);
    pointsSrc.push_back(p2);
    pointsSrc.push_back(p5);
    pointsSrc.push_back(p6);
    pointsSrc.push_back(p7);
    pointsSrc.push_back(p8);
    pointsSrc.push_back(p3);
    pointsSrc.push_back(p4);
    pointsSrc.push_back(p10);
    pointsSrc.push_back(p9);
    
    
    //creating red dots array
    self.redDots=[[NSMutableArray alloc]init];
    
    
    for(int i=0;i<10;i++)
    {
        UIImageView *iv=[[UIImageView alloc]initWithImage:[UIImage imageNamed:@"dot_grey"]];
        
        iv  =[[UIImageView alloc]initWithImage: [self image: iv.image scaledToSize:CGSizeMake(35, 35)] ];
        
        iv.tag=i;
        iv.userInteractionEnabled=YES;
        UILongPressGestureRecognizer *recognizer=[[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(enableMoving:)];
    
        
        [iv addGestureRecognizer:recognizer];
        [self.redDots addObject:iv];
        
        cv::Point_<int> &p=pointsSrc.at(i);
        iv.center=CGPointMake(p.x, p.y);
        
        [self.view addSubview:iv];
        
        
    }
    
    moving=false;
    warping=false;

}



 - (UIImage *)imageWithImage:(UIImage *)image2 scaledToSize:(CGSize)newSize {
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    [image2 drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}






-(IBAction)enableMoving:(UILongPressGestureRecognizer *)recognizer
{
    
    
    if (recognizer.state != UIGestureRecognizerStateBegan)
    {
        for (int i=0; i<10; i++)
        {
            cv::Point_<int> &p=pointsSrc.at(i);
            UIImageView *rd=[self.redDots objectAtIndex:i];
            [rd setImage:[UIImage imageNamed:@"dot_grey"]];
            rd.frame = CGRectMake(p.x, p.y, 35, 35);
            rd.center=CGPointMake(p.x, p.y);
            
            
            
            
        }
   
        
    }
    
    warping=false;
    moving=true;
    self.currentPointNum=recognizer.view.tag+1;
    
    UIImageView *iv= (UIImageView*)recognizer.view;
     

    [iv setImage:[UIImage imageNamed:@"dot_blue"]];
    
    iv.frame = CGRectMake(0, 0, 80, 80);
    iv.center = iv.superview.center;
    
    
    //  CV_POINT :

    cv::Point_<int> &p=pointsSrc.at(self.currentPointNum-1);
    CGPoint newpoint=[recognizer locationInView:self.view];
    p.x=newpoint.x;
    p.y=newpoint.y;

    
    // END CV_POINT :
    
    image  = [self.imageView.image copy] ;
    [self.imageView setImage:image] ;
    pointsDst.clear() ;
    [self placePoints];
 
    
    
    
}




/*
  ____________________
    Pashkovdenis@gmail.com
    2014 :
  _________________

 */
- (UIImage *)image:(UIImage*)originalImage scaledToSize:(CGSize)size
{
    //avoid redundant drawing
    if (CGSizeEqualToSize(originalImage.size, size))
    {
        return originalImage;
    }
    //create drawing context
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0f);
    //draw
    [originalImage drawInRect:CGRectMake(0.0f, 0.0f, size.width, size.height)];
    //capture resultant image
    UIImage *newimage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    //return image
    return newimage;
}


// PlaceOrder
-(void)placePoints
{
    for (int i=0; i<10; i++)
    {
        cv::Point_<int> &p=pointsSrc.at(i);
        UIImageView *rd=[self.redDots objectAtIndex:i];
        rd.center=CGPointMake(p.x, p.y);
        
        
        
        
    }
    
  
    
    
    
    
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    
    
    UITouch *touch=[touches anyObject];
    CGPoint p2=[touch locationInView:self.view];
    
    for (int i=0; i<10; i++)
    {
        cv::Point_<int> &p=pointsSrc.at(i);
        
        int distance=sqrt(pow(p.x-p2.x,2)+pow(p.y-p2.y,2));
        if (distance<20)
        {
            warping=true;
            self.currentPointNum=i+1;
        }
    }
}


/*
    Prceed Transformation Here:  
    pashkovdenis@gmail.com  
 
 
 */



-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    
    
            
            
            
      
    if (moving)
    {
        NSLog(@"Just Moving") ;
        UITouch *touch=[touches anyObject];
        cv::Point_<int> &p=pointsSrc.at(self.currentPointNum-1);
        CGPoint newpoint=[touch locationInView:self.view];
        p.x=newpoint.x;
        p.y=newpoint.y;
        [self placePoints];
        return  ;
    }
     
          
          
          
          
        
    if (warping && moving == false)
    {
       
        
        //warp image
        UITouch *touch=[touches anyObject];

        
    
        
        for (int i=0; i<pointsSrc.size(); i++)
            pointsDst.push_back(pointsSrc.at(i));
        
        CGPoint newpoint=[touch locationInView:self.view];
        cv::Point_<int> &p=pointsSrc.at(self.currentPointNum-1);
        p.x=newpoint.x;
        p.y=newpoint.y;
        
        [self placePoints];
        
        
        p=pointsDst.at(self.currentPointNum-1);
        p.x=newpoint.x;
        p.y=newpoint.y;
        
        
     
        
        
    }
    
    
    
    
    
    
}


/*
  End  Touched  Stack here  :  
  pashkovdenis@gmail.com
 sfrvsrrt 2014:
 
 */

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSLog(@"END ") ;
    
    if (warping &&  moving==false){
    Mat srcMat;
        NSLog(@"apply") ;
    [CVImageConverter CVMat:srcMat FromUIImage:image error:nil];
    
     imwarp.gridSize=25;
     imwarp.alpha=1;
     imwarp.preScale = true ;
      mat=imwarp.setAllAndGenerate(srcMat,  pointsDst,pointsSrc,  srcMat.cols, srcMat.rows);
         [self.imageView setImage:[CVImageConverter UIImageFromCVMat:mat error:nil]];
    }
    
    warping=false;
    moving=false;
    
    for (int i=0; i<10; i++)
    {
        cv::Point_<int> &p=pointsSrc.at(i);
        UIImageView *rd=[self.redDots objectAtIndex:i];
        
      
             [rd setImage:[UIImage imageNamed:@"dot_grey"]];
             rd.frame = CGRectMake(p.x, p.y, 35, 35);
             rd.center=CGPointMake(p.x, p.y);
        
        
        
    }
    warping =false;
    moving = false;
    
    
    
    
    
  
    
    
    self.currentPointNum=0;
    
    
}


/*
 Canceld "
 */



-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    
    
    
    
    
    
    
    NSLog(@"touches cancelled");
    warping = false;
    moving =false;
    
}

@end
