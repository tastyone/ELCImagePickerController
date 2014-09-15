//
//  AssetCell.m
//
//  Created by ELC on 2/15/11.
//  Copyright 2011 ELC Technologies. All rights reserved.
//

#import "ELCAssetCell.h"
#import "ELCAsset.h"

const static CGFloat kELCAssetCell_DefaultCellWidth = 75.f;
const static CGFloat kELCAssetCell_DefaultCellSpace = 4.f;
const static UIEdgeInsets kELCAssetCell_DefaultPaddings = {2.f, 4.f, 2.f, 4.f};

const static CGFloat kELCAssetCell_DefaultCellWidthForRetina = 78.5f;
const static CGFloat kELCAssetCell_DefaultCellSpaceForRetina = 2.f;
const static UIEdgeInsets kELCAssetCell_DefaultPaddingsForRetina = {1.f, 0.f, 1.f, 0.f};

static CGFloat kELCAssetCell_WideWidthWidth = 0.f;
const static CGFloat kELCAssetCell_WideWidthSpace = 1.f;
const static UIEdgeInsets kELCAssetCell_WideWidthPaddings = {1.f, 0.f, 1.f, 0.f};

@interface ELCAssetCell ()

@property (nonatomic, strong) NSArray *rowAssets;
@property (nonatomic, strong) NSMutableArray *imageViewArray;
@property (nonatomic, strong) NSMutableArray *overlayViewArray;

@property (nonatomic, assign) CGFloat cellWidth;
@property (nonatomic, assign) CGFloat cellSpace;
@property (nonatomic, assign) UIEdgeInsets paddings;

@end

@implementation ELCAssetCell

//Using auto synthesizers

+ (CGFloat)narrowWidth;
{
    static CGFloat _w = 0.f;
    if ( _w > 0.f ) return _w;
    _w = MIN([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
    return _w;
}

+ (CGFloat)cellWidth;
{
    if ( [self narrowWidth] > 320.f ) {
        if ( kELCAssetCell_WideWidthWidth < 1.f ) {
            kELCAssetCell_WideWidthWidth = floorf(([self narrowWidth] - kELCAssetCell_WideWidthSpace*3.f - kELCAssetCell_WideWidthPaddings.left - kELCAssetCell_WideWidthPaddings.right) / 4.f);
        }
        return kELCAssetCell_WideWidthWidth;
    } else if ( [UIScreen mainScreen].scale > 1.f ) {
        return kELCAssetCell_DefaultCellWidthForRetina;
    }
    return kELCAssetCell_DefaultCellWidth;
}

+ (CGFloat)cellHeight;
{
    if ( [self narrowWidth] > 320.f ) {
        return [self cellWidth]+kELCAssetCell_WideWidthPaddings.top+kELCAssetCell_WideWidthPaddings.bottom;
    }
    return [UIScreen mainScreen].scale > 1.f ?
    (kELCAssetCell_DefaultCellWidthForRetina+kELCAssetCell_DefaultPaddingsForRetina.top+kELCAssetCell_DefaultPaddingsForRetina.bottom) :
    (kELCAssetCell_DefaultCellWidth+kELCAssetCell_DefaultPaddings.top+kELCAssetCell_DefaultPaddings.bottom);
}
+ (NSUInteger)numberOfColumnsForWidth:(CGFloat)width;
{
    CGFloat availableWidth = width;
    CGFloat cellWidth = 0.f;
    CGFloat cellSpace = 0.f;
    if ( [self narrowWidth] > 320.f ) {
        availableWidth = width - kELCAssetCell_WideWidthPaddings.left - kELCAssetCell_WideWidthPaddings.right;
        cellWidth = [self cellWidth];
        cellSpace = kELCAssetCell_WideWidthSpace;
    } else if ( [UIScreen mainScreen].scale > 1.f ) {
        availableWidth = width - kELCAssetCell_DefaultPaddingsForRetina.left - kELCAssetCell_DefaultPaddingsForRetina.right;
        cellWidth = kELCAssetCell_DefaultCellWidthForRetina;
        cellSpace = kELCAssetCell_DefaultCellSpaceForRetina;
    } else {
        availableWidth = width - kELCAssetCell_DefaultPaddings.left - kELCAssetCell_DefaultPaddings.right;
        cellWidth = kELCAssetCell_DefaultCellWidth;
        cellSpace = kELCAssetCell_DefaultCellSpace;
    }
    availableWidth = availableWidth - cellWidth;
    if ( availableWidth < cellWidth ) return 0;
    if ( availableWidth < 0.f ) return 1;
    return 1 + (NSUInteger)floorf(availableWidth / (cellWidth + cellSpace));
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
	if (self) {
        self.backgroundColor = [UIColor clearColor];
        
        UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(cellTapped:)];
        [self addGestureRecognizer:tapRecognizer];
        
        NSMutableArray *mutableArray = [[NSMutableArray alloc] initWithCapacity:4];
        self.imageViewArray = mutableArray;
        
        NSMutableArray *overlayArray = [[NSMutableArray alloc] initWithCapacity:4];
        self.overlayViewArray = overlayArray;
        
        if ( [[self class] narrowWidth] > 320.f ) {
            self.cellWidth = [[self class] cellWidth];
            self.cellSpace = kELCAssetCell_WideWidthSpace;
            self.paddings = kELCAssetCell_WideWidthPaddings;
        } else if ( [UIScreen mainScreen].scale > 1.f ) {
            self.cellWidth = kELCAssetCell_DefaultCellWidthForRetina;
            self.cellSpace = kELCAssetCell_DefaultCellSpaceForRetina;
            self.paddings = kELCAssetCell_DefaultPaddingsForRetina;
        } else {
            self.cellWidth = kELCAssetCell_DefaultCellWidth;
            self.cellSpace = kELCAssetCell_DefaultCellSpace;
            self.paddings = kELCAssetCell_DefaultPaddings;
        }
	}
	return self;
}

- (void)setAssets:(NSArray *)assets
{
    self.rowAssets = assets;
	for (UIImageView *view in _imageViewArray) {
        [view removeFromSuperview];
	}
    for (UIImageView *view in _overlayViewArray) {
        [view removeFromSuperview];
	}
    //set up a pointer here so we don't keep calling [UIImage imageNamed:] if creating overlays
    UIImage *overlayImage = nil;
    for (int i = 0; i < [_rowAssets count]; ++i) {

        ELCAsset *asset = [_rowAssets objectAtIndex:i];

        if (i < [_imageViewArray count]) {
            UIImageView *imageView = [_imageViewArray objectAtIndex:i];
            imageView.image = [UIImage imageWithCGImage:asset.asset.thumbnail];
        } else {
            UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageWithCGImage:asset.asset.thumbnail]];
            [_imageViewArray addObject:imageView];
        }
        
        if (i < [_overlayViewArray count]) {
            UIImageView *overlayView = [_overlayViewArray objectAtIndex:i];
            overlayView.hidden = asset.selected ? NO : YES;
        } else {
            if (overlayImage == nil) {
//                overlayImage = [UIImage imageNamed:@"Overlay.png"];
            }
            UIImageView *overlayView = [[UIImageView alloc] initWithImage:overlayImage];
            overlayView.layer.borderColor = c_retricaHeadColor.CGColor;
            overlayView.layer.borderWidth = 10.f;
            [_overlayViewArray addObject:overlayView];
            overlayView.hidden = asset.selected ? NO : YES;
        }
    }
}

- (void)cellTapped:(UITapGestureRecognizer *)tapRecognizer
{
    CGPoint point = [tapRecognizer locationInView:self];
//    CGFloat totalWidth = self.paddings.left + self.paddings.right + (self.rowAssets.count * self.cellWidth) + (self.rowAssets.count - 1) * self.cellSpace;
    CGFloat startX = self.paddings.left;
    
	CGRect frame = CGRectMake(startX, self.paddings.top, self.cellWidth, self.cellWidth);
	
	for (int i = 0; i < [_rowAssets count]; ++i) {
        if (CGRectContainsPoint(frame, point)) {
            ELCAsset *asset = [_rowAssets objectAtIndex:i];
            asset.selected = !asset.selected;
            UIImageView *overlayView = [_overlayViewArray objectAtIndex:i];
            overlayView.hidden = !asset.selected;
            break;
        }
        frame.origin.x = frame.origin.x + frame.size.width + self.cellSpace;
    }
}

- (void)layoutSubviews
{    
//    CGFloat totalWidth = self.paddings.left + self.paddings.right + (self.rowAssets.count * self.cellWidth) + (self.rowAssets.count - 1) * self.cellSpace;
    CGFloat startX = self.paddings.left;
    
	CGRect frame = CGRectMake(startX, self.paddings.top, self.cellWidth, self.cellWidth);
	
	for (int i = 0; i < [_rowAssets count]; ++i) {
		UIImageView *imageView = [_imageViewArray objectAtIndex:i];
		[imageView setFrame:frame];
		[self addSubview:imageView];
        
        UIImageView *overlayView = [_overlayViewArray objectAtIndex:i];
        [overlayView setFrame:frame];
        [self addSubview:overlayView];
		
		frame.origin.x = frame.origin.x + frame.size.width + self.cellSpace;
	}
}


@end
