//
//  ELCImagePickerController.m
//  ELCImagePickerDemo
//
//  Created by ELC on 9/9/10.
//  Copyright 2010 ELC Technologies. All rights reserved.
//

#import "ELCImagePickerController.h"
#import "ELCAsset.h"
#import "ELCAssetCell.h"
#import "ELCAssetTablePicker.h"
#import "ELCAlbumPickerController.h"
#import <CoreLocation/CoreLocation.h>

@implementation ELCImagePickerController

- (void)cancelImagePicker
{
	if([_pickerDelegate respondsToSelector:@selector(elcImagePickerControllerDidCancel:)]) {
		[_pickerDelegate performSelector:@selector(elcImagePickerControllerDidCancel:) withObject:self];
	}
}

- (BOOL)shouldSelectAsset:(ELCAsset *)asset previousCount:(NSUInteger)previousCount {
    BOOL shouldSelect = previousCount < self.maximumImagesCount;
    if (!shouldSelect) {
        NSString *title = [NSString stringWithFormat:NSLocalizedString(@"Only %d photos please!", nil), self.maximumImagesCount];
        NSString *message = [NSString stringWithFormat:NSLocalizedString(@"You can only send %d photos at a time.", nil), self.maximumImagesCount];
        [[[UIAlertView alloc] initWithTitle:title
                                    message:message
                                   delegate:nil
                          cancelButtonTitle:nil
                          otherButtonTitles:NSLocalizedString(@"Okay", nil), nil] show];
    }
    return shouldSelect;
}

- (void)selectedAssets:(NSArray *)assets
{
	NSMutableArray *returnArray = [[[NSMutableArray alloc] init] autorelease];
	
    CGFloat progress = 0.f;
    CGFloat unitProgress = assets.count > 0 ? 1.f/assets.count : 0.f;
    
    if ( _pickerDelegate && [_pickerDelegate respondsToSelector:@selector(elcImagePickerController:willPrepareAssets:)] ) {
        [_pickerDelegate elcImagePickerController:self willPrepareAssets:assets];
    }
    
	for(ALAsset *asset in assets) {
		NSMutableDictionary *workingDictionary = [[NSMutableDictionary alloc] init];
		
		CLLocation* wgs84Location = [asset valueForProperty:ALAssetPropertyLocation];
		if (wgs84Location) {
			[workingDictionary setObject:wgs84Location forKey:ALAssetPropertyLocation];
		}
    
		[workingDictionary setObject:[asset valueForProperty:ALAssetPropertyType] forKey:@"UIImagePickerControllerMediaType"];
        ALAssetRepresentation *assetRep = [asset defaultRepresentation];
        
//        if ( !assetRep ) {
//            NSArray* reps = [asset valueForProperty:ALAssetPropertyRepresentations];
//            NSLog(@"reps: %@", reps);
//            if ( reps && reps.count > 0 ) {
//                for (NSString* uti in reps) {
//                    assetRep = [asset representationForUTI:uti];
//                    if ( assetRep ) break;
//                }
//            }
//        }
        
        progress += unitProgress*0.2f;
        if ( _pickerDelegate && [_pickerDelegate respondsToSelector:@selector(elcImagePickerController:preparingInProgress:)] ) {
            [_pickerDelegate elcImagePickerController:self preparingInProgress:progress];
        }
        
//        CGImageRef imgRef = [assetRep fullScreenImage];
        CGImageRef imgRef = [assetRep fullResolutionImage];
        
        progress += unitProgress*0.4f;
        if ( _pickerDelegate && [_pickerDelegate respondsToSelector:@selector(elcImagePickerController:preparingInProgress:)] ) {
            [_pickerDelegate elcImagePickerController:self preparingInProgress:progress];
        }
        
        UIImage *img = [UIImage imageWithCGImage:imgRef
                                           scale:1.0f
                                     orientation:(UIImageOrientation)assetRep.orientation];
        
        progress += unitProgress*0.2f;
        if ( _pickerDelegate && [_pickerDelegate respondsToSelector:@selector(elcImagePickerController:preparingInProgress:)] ) {
            [_pickerDelegate elcImagePickerController:self preparingInProgress:progress];
        }
        
        [workingDictionary setObject:img forKey:@"UIImagePickerControllerOriginalImage"];
		[workingDictionary setObject:[[asset valueForProperty:ALAssetPropertyURLs] valueForKey:[[[asset valueForProperty:ALAssetPropertyURLs] allKeys] objectAtIndex:0]] forKey:@"UIImagePickerControllerReferenceURL"];
        [workingDictionary setObject:assetRep.metadata forKey:@"UIImagePickerControllerMediaMetadata"];
		
		[returnArray addObject:workingDictionary];
		
		[workingDictionary release];
        
        progress += unitProgress*0.2f;
        if ( _pickerDelegate && [_pickerDelegate respondsToSelector:@selector(elcImagePickerController:preparingInProgress:)] ) {
            [_pickerDelegate elcImagePickerController:self preparingInProgress:progress];
        }
	}
	if(_pickerDelegate != nil && [_pickerDelegate respondsToSelector:@selector(elcImagePickerController:didFinishPickingMediaWithInfo:)]) {
		[_pickerDelegate performSelector:@selector(elcImagePickerController:didFinishPickingMediaWithInfo:) withObject:self withObject:[NSArray arrayWithArray:returnArray]];
	} else {
        [self popToRootViewControllerAnimated:NO];
    }
    
    if ( _pickerDelegate && [_pickerDelegate respondsToSelector:@selector(elcImagePickerControllerDidFinishPrepareAssets:)] ) {
        [_pickerDelegate elcImagePickerControllerDidFinishPrepareAssets:self];
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return YES;
    } else {
        return toInterfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
    }
}

#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning
{
    NSLog(@"ELC Image Picker received memory warning.");
    
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
    [super viewDidUnload];
}


- (void)dealloc
{
    NSLog(@"deallocing ELCImagePickerController");
    [super dealloc];
}

@end
