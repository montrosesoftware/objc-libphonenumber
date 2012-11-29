//
//  libphonenumberFormatter.m
//  libphonenumber_js
//
//  Created by Kent Sutherland on 8/6/12.
//  Copyright 2012 Flexibits Inc.
//  
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  
//     http://www.apache.org/licenses/LICENSE-2.0
//  
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "libphonenumberFormatter.h"

//JavaScript that is called by stringForObjectValue:
NSString * const FormatScript = @"(function() {\
var formatter = new i18n.phonenumbers.AsYouTypeFormatter(\"%@\");\
var ret = \"\";\
var s = \"%@\";\
for (var i = 0; i < s.length; i++)\
    if (/[A-Za-z]/.test(s) || s.charAt(i) != ' ' && s.charAt(i) != '-' && s.charAt(i) != '(' && s.charAt(i) != ')')\
        ret = formatter.inputDigit(s.charAt(i));\
return ret.trim();\
})();";

@interface libphonenumberFormatter ()
- (void)_setupJSContext;
- (NSString *)_runScript:(NSString *)scriptString;
@end

@implementation libphonenumberFormatter

static UIWebView *_webView;

- (id)init
{
    if ( (self = [super init]) ) {
        [self setCountryCode:[[NSLocale currentLocale] objectForKey:NSLocaleCountryCode]];
        [self _setupJSContext];
    }
    return self;
}

- (NSString *)stringForObjectValue:(id)anObject
{
    NSAssert([anObject isKindOfClass:[NSString class]], @"anObject must be a string");
    anObject = [anObject stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
    
    NSString *formatScriptString = [NSString stringWithFormat:FormatScript, self.countryCode, anObject];
    NSString *result = [self _runScript:formatScriptString];
    
    return result;
}

#pragma mark - Private

- (void)_setupJSContext
{
    static dispatch_once_t singletonPredicate;
    dispatch_once(&singletonPredicate, ^{
        _webView = [UIWebView new];
        NSString *jsPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"libphonenumber" ofType:@"js"];
        NSString *html = [NSString stringWithFormat:@"<html><head><script src=\"file://%@\" type=\"text/javascript\"></script></head><body></body></html>", jsPath];
        [_webView loadHTMLString:html baseURL:nil];
    });
}

- (NSString *)_runScript:(NSString *)scriptString
{
    @synchronized(_webView) {
        return [_webView stringByEvaluatingJavaScriptFromString:scriptString];
    }
}

@end
