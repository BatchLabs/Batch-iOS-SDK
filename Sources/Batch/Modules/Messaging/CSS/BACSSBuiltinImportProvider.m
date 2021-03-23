//
//  BACSSBuiltinImportProvider.m
//  Batch
//
//  Copyright © 2016 Batch. All rights reserved.
//

#import <Batch/BACSSBuiltinImportProvider.h>

static NSDictionary<NSString*, NSArray<NSString*>*> *kBACSSBuiltinImportProviderMetaImports;

@implementation BACSSBuiltinImportProvider

+ (void)load
{
    kBACSSBuiltinImportProviderMetaImports =
    @{@"generic1-h-cta": @[@"generic1_h-cta", @"generic1_base"],
      @"generic1-h-cta-legacy": @[@"generic1_h-cta-legacy", @"generic1_base"],
      @"generic1-v-cta": @[@"generic1_v-cta", @"generic1_base"],
      @"image1-fullscreen": @[@"image1_fullscreen", @"image1_base"],
      @"image1-detached": @[@"image1_detached", @"image1_base"],
      };
}

- (NSString* _Nullable)contentForImportNamed:(NSString* _Nonnull)importName
{
    NSArray<NSString*> *metaImportNames = [kBACSSBuiltinImportProviderMetaImports objectForKey:importName];
    if (metaImportNames != nil)
    {
        NSMutableString *fullContent = [NSMutableString new];
        for (NSString* metaImportName in metaImportNames)
        {
            NSString *metaImportContent = [self contentForImportNamed:metaImportName];
            if ([metaImportContent length] > 0)
            {
                [fullContent appendString:metaImportContent];
            }
        }
        
        if ([fullContent length] > 0)
        {
            return [fullContent copy];
        }
        else
        {
            return nil;
        }
    }
    
    if ([importName isEqualToString:@"generic1_h-cta"])
    {
        return @"*{--cta-h-m:0;--cta1-br:8;--cta2-br:8;--ios-padding-hack:-1;}@android{#ctas{border-color:var(--separator-bc);border-width:var(--separator-bw);margin:-1}}@ios{.ctas-h-sep{width:8}.btn{compression-res-h:1000;content-hug-h:250}#ctas{safe-area:copy-padding;height:50;}}.btn{height:50;margin:var(--cta-h-m)}";
    }
    else if ([importName isEqualToString:@"generic1_h-cta-legacy"])
    {
        return @"*{--separator-bc:#DCA6C6;--separator-bw:1;--cta-h-m:0;--ios-padding-hack:-1}@android{#ctas{border-color:var(--separator-bc);border-width:var(--separator-bw);margin:-1}}@ios{.ctas-h-sep{width:8}.btn{compression-res-h:1000;content-hug-h:250}#ctas{safe-area:auto;height:50;padding-left:var(--ios-padding-hack);padding-right:var(--ios-padding-hack);padding-bottom:var(--ios-padding-hack)}#ctas-inner{border-color:var(--separator-bc);border-width:var(--separator-bw)}}.btn{height:50;border-radius: 8;margin:var(--cta-h-m)}";
    }
    else if ([importName isEqualToString:@"generic1_v-cta"])
    {
        return @"*{--cta-v-m:10;--cta-v-p:15}.btn{margin:var(--cta-v-m);padding:var(--cta-v-p)}.detached_ctas{padding-bottom:0}";
    }
    else if ([importName isEqualToString:@"generic1_base"])
    {
        return @"@android{.text{flex-shrink:0}#body{flex-grow:0;flex-shrink:1}.btn{flex-shrink:0}#ctas{flex-shrink:0}#close{padding:10;margin-top:10;margin-right:10}}@ios{#root{statusbar:var(--mode)}}*{--mode:light;--content-vpadding:8;--general-bg:#923d6f;--close-bg:#ffffff;--close-c:#8d426e;--image-bs:fill;--header-fs:13;--header-fw:bold;--header-m:0 0 10 0;--header-c:#c784ac;--title-fs:24;--title-fw:bold;--title-m:0 10 10 10;--title-c:#ffffff;--text-fs:15;--text-fw:normal;--text-m:0 10 0 10;--text-c:#e5c7d9;--cta-c-p:0;--cta1-m:0;--cta1-br:0;--cta1-c:#ffffff;--cta1-bg:transparent;--cta1-fw:normal;--cta2-m:0;--cta2-br:0;--cta2-c:#c784ac;--cta2-bg:transparent;--cta2-fw:normal}#placeholder{loader:var(--mode)}.text{margin-left:30;margin-right:30}#root{background-color:var(--general-bg);statusbar-bg:translucent}#image{scale:var(--image-bs)}.btn{elevation:0;background-color:transparent;color:#ffffff;font-weight:var(--cta-fw)}#ctas{safe-area:copy-padding;padding:var(--cta-p)}#close{background-color:var(--close-bg);margin-top:20;margin-right:20;color:var(--close-c);glyph-padding:20}#body{font-size:var(--text-fs);font-weight:var(--text-fw);margin:var(--text-m);color:var(--text-c);line-height:1.2;padding-left:5;padding-right:5}#h1{font-size:var(--header-fs);font-weight:var(--header-fw);margin:var(--header-m);color:var(--header-c)}#h2{font-size:var(--title-fs);font-weight:var(--title-fw);margin:var(--title-m);color:var(--title-c);line-height:1.1}#cta1{margin:var(--cta1-m);border-radius:var(--cta1-br);color:var(--cta1-c);background-color:var(--cta1-bg);font-weight:var(--cta1-fw)}#cta2{margin:var(--cta2-m);border-radius:var(--cta2-br);color:var(--cta2-c);background-color:var(--cta2-bg);font-weight:var(--cta2-fw)}#content{padding-top:var(--content-vpadding);padding-bottom:var(--content-vpadding);safe-area:copy-padding;safe-area-fit:loose}";
    }
    else if ([importName isEqualToString:@"banner1"])
    {
        return @"@android{#root{background-color:var(--bg-color);margin:var(--margin);elevation:var(--android-shadow);border-radius:var(--corner-radius)}.btn{elevation:0}#countdown{height:4}#close{margin:0}}@ios{#root{background-color:#00000000;statusbar:var(--mode)}#content{background-color:var(--bg-color);margin:var(--margin);border-radius:var(--corner-radius);shadow-layer:var(--ios-shadow)}}@media ios and (min-width:768){#content{margin:15;border-radius:5;shadow-layer:15 .5 #000000;max-width:500;align:var(--ios-responsive-align)}}*{--mode:auto;--valign:bottom;--countdown-color:#40a3e9;--countdown-valign:top;--ios-shadow:15 0.5 #000000;--ios-responsive-align:center;--android-shadow:10;--title-color:#000000;--title-font-weight:bold;--title-font-size:15;--body-font-size:13;--body-color:#000000;--bg-color:#f1f1f1;--text-side-padding:45;--close-color:#000000;--close-bg-color:#00000000;--cta-android-shadow:auto;--cta-font-size:14;--cta-font-weight:bold;--cta1-color:#40a3e9;--cta1-text-color:#ffffff;--cta2-color:#dbdbdb;--cta2-text-color:#000000;--cta-container-width:100%;--margin:0;--corner-radius:0}#content{vertical-align:var(--valign)}.text{text-align:center;margin-left:var(--text-side-padding);margin-right:var(--text-side-padding);margin-top:20}#body{margin-bottom:20;color:var(--body-color);font-size:var(--body-font-size);font-weight:var(--body-font-weight);padding-left:5;padding-right:5}#title{color:var(--title-color);font-size:var(--title-font-size);font-weight:var(--title-font-weight)}#close{background-color:var(--close-bg-color);margin:10;color:var(--close-color);glyph-padding:20}#ctas{width:var(--cta-container-width);margin-bottom:10}#cta1{color:var(--cta1-text-color);background-color:var(--cta1-color)}#cta2{color:var(--cta2-text-color);background-color:var(--cta2-color)}.btn{font-size:var(--cta-font-size);font-weight:var(--cta-font-weight)}.btn-v{width:100%;margin-left:20;margin-right:20;margin-bottom:10;border-radius:5;padding:10;elevation:var(--cta-android-shadow)}.btn-h{flex-grow:1;border-radius:5;padding:10;elevation:var(--cta-android-shadow)}#img{z-index:back;height:fill;scale:fill;align:left;width:auto}#countdown{height:2;color:var(--countdown-color);vertical-align:var(--countdown-valign)}";
    }
    else if ([importName isEqualToString:@"modal1"])
    {
        return @"@android{#root{background-color:var(--backdrop-bg-color);statusbar-bg:var(--android-statusbar-bg)}#container{vertical-align:center;background-color:var(--bg-color);margin:var(--margin);elevation:var(--android-shadow);border-radius:var(--corner-radius)}.btn{elevation:0}#close{z-index:151;vertical-align:top;margin:0}#img{z-index:150}#countdown{z-index:152}}@ios{#root{background-color:var(--backdrop-bg-color);statusbar:var(--mode)}#content{background-color:var(--bg-color);margin:var(--margin);border-radius:var(--corner-radius);shadow-layer:var(--ios-shadow)}}@media ios and (min-width:768){#content{margin:15;border-radius:5;shadow-layer:15 .5 #000000;width:500;max-width:500;align:var(--ios-responsive-align)}}*{--mode:auto;--android-statusbar-bg:translucent;--valign:center;--countdown-color:#40a3e9;--countdown-valign:top;--ios-shadow:15 0.5 #000000;--ios-responsive-align:center;--android-shadow:10;--title-color:#000000;--title-font-weight:bold;--title-font-size:15;--body-font-size:13;--body-color:#000000;--bg-color:#f1f1f1;--backdrop-bg-color:#88000000;--text-side-padding:45;--close-color:#000000;--close-bg-color:#00000000;--cta-android-shadow:auto;--cta-font-size:14;--cta-font-weight:bold;--cta1-color:#40a3e9;--cta1-text-color:#ffffff;--cta2-color:#dbdbdb;--cta2-text-color:#000000;--cta-container-width:100%;--margin:10;--corner-radius:5}#content{vertical-align:var(--valign)}.text{text-align:center;margin-left:var(--text-side-padding);margin-right:var(--text-side-padding);margin-top:20}#body{margin-bottom:20;color:var(--body-color);font-size:var(--body-font-size);font-weight:var(--body-font-weight);padding-left:5;padding-right:5}#title{color:var(--title-color);font-size:var(--title-font-size);font-weight:var(--title-font-weight)}#close{background-color:var(--close-bg-color);margin:10;color:var(--close-color);glyph-padding:20}#ctas{width:var(--cta-container-width);margin-bottom:10}#cta1{color:var(--cta1-text-color);background-color:var(--cta1-color)}#cta2{color:var(--cta2-text-color);background-color:var(--cta2-color)}.btn{font-size:var(--cta-font-size);font-weight:var(--cta-font-weight)}.btn-v{width:100%;margin-left:20;margin-right:20;margin-bottom:10;border-radius:5;padding:10;elevation:var(--cta-android-shadow)}.btn-h{flex-grow:1;border-radius:5;padding:10;elevation:var(--cta-android-shadow)}#img{z-index:back;height:fill;scale:fill;align:left;width:auto}#countdown{height:2;color:var(--countdown-color);vertical-align:var(--countdown-valign)}";
    }
    else if ([importName isEqualToString:@"banner-icon"] || [importName isEqualToString:@"modal-icon"])
    {
        return @"*{--image-bs:fill;--image-h:150}#img{z-index:back;height:var(--image-h);scale:var(--image-bs);align:left;vertical-align:top;width:auto}#title{margin-top:var(--image-h);padding-top:20}";
    }
    else if ([importName isEqualToString:@"image1_base"])
    {
        return @"@android{#root{statusbar-bg:#000000;statusbar:dark}}*{--close-bg-color:#000000;--close-color:#ffffff;--bg-color:#77000000;--container-bg-color:#000000}#close{background-color:var(--close-bg-color);color:var(--close-color)}#background{background-color:var(--bg-color)}#container{background-color:var(--container-bg-color)}";
    }
    else if ([importName isEqualToString:@"image1_detached"])
    {
        return @"@android{#close{z-index:11}#container{elevation:10}}*{--ios-shadow:15 0.5 #000000;--corner-radius:5}#container{shadow-layer:var(--ios-shadow);border-radius:var(--corner-radius)}";
    }
    else if ([importName isEqualToString:@"image1_fullscreen"])
    {
        return @"*{--image-bs:fit}#image{scale:var(--image-bs)}";
    }
    else if ([importName isEqualToString:@"webview1"])
    {
        return @"*{--mode:light;--ios-loader-size:large;--android-statusbar-bg:#000000;--android-statusbar-fg:light;--bg-color:#000000;--close-bg-color:#000000;--close-color:#ffffff;--ios-safe-area:no}@android{#root{statusbar:var(--android-statusbar-fg);statusbar-bg:var(--android-statusbar-bg)}}@ios{#root{statusbar:var(--mode);loader-size:var(--ios-loader-size)}#webview{safe-area:var(--ios-safe-area)}}#close{background-color:var(--close-bg-color);color:var(--close-color)}#root{background-color:var(--bg-color);loader:var(--mode)}";
    }
    return nil;
}

@end
