//
//  MGTwitterXMLParser.m
//  MGTwitterEngine
//
//  Created by Matt Gemmell on 18/02/2008.
//  Copyright 2008 Instinctive Code.
//

#import "MGTwitterXMLParser.h"


@implementation MGTwitterXMLParser


#pragma mark Creation and Destruction


+ (id)parserWithXML:(NSData *)theXML delegate:(NSObject *)theDelegate 
connectionIdentifier:(NSString *)identifier requestType:(MGTwitterRequestType)reqType 
       responseType:(MGTwitterResponseType)respType
{
    id parser = [[self alloc] initWithXML:theXML 
                                 delegate:theDelegate 
                     connectionIdentifier:identifier 
                              requestType:reqType
                             responseType:respType];
    return [parser autorelease];
}


- (id)initWithXML:(NSData *)theXML delegate:(NSObject *)theDelegate 
connectionIdentifier:(NSString *)theIdentifier requestType:(MGTwitterRequestType)reqType 
     responseType:(MGTwitterResponseType)respType
{
    if (self = [super init]) {
        xml = [theXML retain];
        identifier = [theIdentifier retain];
        requestType = reqType;
        responseType = respType;
        delegate = theDelegate;
        parsedObjects = [[NSMutableArray alloc] initWithCapacity:0];
        
        // Set up the parser object.
        parser = [[NSXMLParser alloc] initWithData:xml];
        [parser setDelegate:self];
        [parser setShouldReportNamespacePrefixes:NO];
        [parser setShouldProcessNamespaces:NO];
        [parser setShouldResolveExternalEntities:NO];
        
        // Begin parsing.
        [parser parse];
    }
    
    return self;
}


- (void)dealloc
{
    [parser release];
    [parsedObjects release];
    [xml release];
    [identifier release];
    delegate = nil;
    [super dealloc];
}


#pragma mark NSXMLParser delegate methods


- (void)parserDidStartDocument:(NSXMLParser *)theParser
{
    ////YFLog(@"Parsing begun");
}


- (void)parserDidEndDocument:(NSXMLParser *)theParser
{
    ////YFLog(@"Parsing complete: %@", parsedObjects);
    [delegate parsingSucceededForRequest:identifier ofResponseType:responseType 
                       withParsedObjects:parsedObjects];
}


- (void)parser:(NSXMLParser *)theParser didStartElement:(NSString *)elementName 
  namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName 
    attributes:(NSDictionary *)attributeDict
{
    ////YFLog(@"Started element: %@ (%@)", elementName, attributeDict);
}


- (void)parser:(NSXMLParser *)theParser foundCharacters:(NSString *)characters
{
    ////YFLog(@"Found characters: %@", characters);
}


- (void)parser:(NSXMLParser *)theParser didEndElement:(NSString *)elementName 
  namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    ////YFLog(@"Ended element: %@", elementName);
    [self setLastOpenedElement:nil];
    
    if ([elementName isEqualToString:@"protected"] 
        || [elementName isEqualToString:@"truncated"] 
        || [elementName isEqualToString:@"following"]) {
        // Change "true"/"false" into an NSNumber with a BOOL value.
        NSNumber *boolNumber = [NSNumber numberWithBool:[[currentNode objectForKey:elementName] isEqualToString:@"true"]];
        [currentNode setObject:boolNumber forKey:elementName];
    } else if ([elementName isEqualToString:@"created_at"]) {
        // Change date-string into an NSDate.
        //NSDate *creationDate = [NSDate dateWithNaturalLanguageString:[currentNode objectForKey:elementName]];
        NSString *value = [currentNode objectForKey:elementName];
        
        NSString *dateFormat = nil;
        if ([value hasSuffix:@"+0000"])
        {
            // format for Search API: "Fri, 06 Feb 2009 07:28:06 +0000"
            // strptime([value UTF8String], "%a, %d %b %Y %H:%M:%S +0000", &theTime);
            dateFormat = @"EEE, dd MMM yyyy HH:mm:ss ZZZ";
        }
        else
        {
            // format for REST API: "Thu Jan 15 02:04:38 +0000 2009"
            // strptime([value UTF8String], "%a %b %d %H:%M:%S +0000 %Y", &theTime);
            dateFormat = @"EEE MMM dd HH:mm:ss ZZZ yyyy";
        }
        
        NSDateFormatterBehavior def = [NSDateFormatter defaultFormatterBehavior];
        [NSDateFormatter setDefaultFormatterBehavior:NSDateFormatterBehavior10_4];

        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:dateFormat];
        NSDate *creationDate = [dateFormatter dateFromString:value];
        [dateFormatter release];
        
        if (creationDate) {
            [currentNode setObject:creationDate forKey:elementName];
        }
        
        [NSDateFormatter setDefaultFormatterBehavior:def];
    }
}


- (void)parser:(NSXMLParser *)theParser foundAttributeDeclarationWithName:(NSString *)attributeName 
    forElement:(NSString *)elementName type:(NSString *)type defaultValue:(NSString *)defaultValue
{
    ////YFLog(@"Found attribute: %@ (%@) [%@] {%@}", attributeName, elementName, type, defaultValue);
}


- (void)parser:(NSXMLParser *)theParser foundIgnorableWhitespace:(NSString *)whitespaceString
{
    ////YFLog(@"Found ignorable whitespace: %@", whitespaceString);
}


- (void)parser:(NSXMLParser *)theParser parseErrorOccurred:(NSError *)parseError
{
    ////YFLog(@"Parsing error occurred: %@", parseError);
    [delegate parsingFailedForRequest:identifier ofResponseType:responseType 
                            withError:parseError];
}


#pragma mark Accessors


- (NSString *)lastOpenedElement {
    return [[lastOpenedElement retain] autorelease];
}


- (void)setLastOpenedElement:(NSString *)value {
    if (lastOpenedElement != value) {
        [lastOpenedElement release];
        lastOpenedElement = [value copy];
    }
}


#pragma mark Utility methods


- (void)addSource
{
    if (![currentNode objectForKey:TWITTER_SOURCE_REQUEST_TYPE]) {
        [currentNode setObject:[NSNumber numberWithInt:requestType] 
                        forKey:TWITTER_SOURCE_REQUEST_TYPE];
    }
}


@end
