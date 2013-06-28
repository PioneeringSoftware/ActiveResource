// ActiveResource NSEntityDescription+ActiveResource.m
//
// Copyright © 2012, Roy Ratcliffe, Pioneering Software, United Kingdom
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
//	The above copyright notice and this permission notice shall be included in
//	all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS," WITHOUT WARRANTY OF ANY KIND, EITHER
// EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO
// EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES
// OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
// ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
// DEALINGS IN THE SOFTWARE.
//
//------------------------------------------------------------------------------

#import "NSEntityDescription+ActiveResource.h"
#import "NSAttributeDescription+ActiveResource.h"
#import "ARResource.h"

// for -[ASInflector underscore:camelCasedWord]
#import <ActiveSupport/ActiveSupport.h>

@implementation NSEntityDescription(ActiveResource)

- (NSDictionary *)propertiesFromResource:(ARResource *)resource
{
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	for (NSPropertyDescription *property in [self properties])
	{
		if ([property isKindOfClass:[NSAttributeDescription class]])
		{
			// Iterate through all the attribute descriptions, ignoring
			// relationships and fetched properties.
			NSAttributeDescription *attribute = (NSAttributeDescription *)property;
			id value = [attribute valueInResource:resource];
			[attributes setObject:value ? value : [NSNull null] forKey:[attribute name]];
		}
	}
	return [attributes copy];
}

- (NSDictionary *)attributesFromObject:(NSObject *)object
{
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	for (NSPropertyDescription *property in [self properties])
	{
		if ([property isKindOfClass:[NSAttributeDescription class]])
		{
			NSAttributeDescription *attribute = (NSAttributeDescription *)property;
			id value = [attribute valueInObject:object];
			[attributes setObject:value ? value : [NSNull null] forKey:[[ASInflector defaultInflector] underscore:[attribute name]]];
		}
	}
	return [attributes copy];
}

@end
