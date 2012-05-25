// ActiveResourceKitTests IncrementalStoreTests.m
//
// Copyright © 2012, Roy Ratcliffe, Pioneering Software, United Kingdom
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the “Software”), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
//	The above copyright notice and this permission notice shall be included in
//	all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED “AS IS,” WITHOUT WARRANTY OF ANY KIND, EITHER
// EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO
// EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES
// OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
// ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
// DEALINGS IN THE SOFTWARE.
//
//------------------------------------------------------------------------------

#import "IncrementalStoreTests.h"

// for ARIncrementalStore
#import "ARIncrementalStore.h"

// for ActiveResourceKitTestsBaseURL
#import "ActiveResourceKitTests.h"

@implementation IncrementalStoreTests

@synthesize context = _context;

- (NSPersistentStoreCoordinator *)coordinator
{
	return [[self context] persistentStoreCoordinator];
}

- (NSManagedObjectModel *)model
{
	return [[self coordinator] managedObjectModel];
}

/*!
 * @brief Builds a Core Data stack. @details Loads the data model, initialises
 * the coordinator with the model, adds the incremental store to the
 * coordinator, finally attaches the coordinator to a new main-queue context.
 */
- (void)setUp
{
	// Where is the data model? Does it exist in the main bundle? No. The binary
	// at /Applications/Xcode.app/Contents/Developer/Tools/otest executes the
	// tests. Instead, look for the data model within the "octest" bundle from
	// where the test launcher finds this test class.
	NSBundle *bundle = [NSBundle bundleForClass:[self class]];
	NSURL *modelURL = [bundle URLForResource:@"ActiveResourceKitTests" withExtension:@"momd"];
	NSManagedObjectModel *model = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
	NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
	
	NSError *__autoreleasing error = nil;
	NSPersistentStore *store = [coordinator addPersistentStoreWithType:[ARIncrementalStore storeType]
														 configuration:nil
																   URL:ActiveResourceKitTestsBaseURL()
															   options:nil
																 error:&error];
	STAssertNotNil(store, nil);
	STAssertNil(error, nil);
	
	NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
	[context setPersistentStoreCoordinator:coordinator];
	[self setContext:context];
}

- (void)testPeople
{
	// Fetch all the people. Assert their non-nil names. All names are non-nil
	// including people with no names. People with no names have name equal to
	// null, where null is not exactly nil albeit equivalent depending its
	// interpretation.
	NSError *__autoreleasing error = nil;
	NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Person"];
	NSArray *people = [[self context] executeFetchRequest:request error:&error];
	for (NSManagedObject *person in people)
	{
		NSString *name = [person valueForKey:@"name"];
		NSLog(@"person named %@", name);
		STAssertNotNil(name, nil);
	}
}

- (void)testPosts
{
	NSError *__autoreleasing error = nil;
	NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Post"];
	NSArray *posts = [[self context] executeFetchRequest:request error:&error];
	for (NSManagedObject *post in posts)
	{
		NSString *title = [post valueForKey:@"title"];
		NSManagedObject *person = [post valueForKey:@"poster"];
		NSString *name = [person valueForKey:@"name"];
		NSLog(@"post entitled %@ by %@", title, name);
		STAssertNotNil(title, nil);
	}
}

- (void)testComments
{
	NSError *__autoreleasing error = nil;
	NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Post"];
	NSArray *posts = [[self context] executeFetchRequest:request error:&error];
	for (NSManagedObject *post in posts)
	{
		NSString *title = [post valueForKey:@"title"];
		NSLog(@"post entitled %@", title);
		STAssertNotNil(title, nil);
		for (NSManagedObject *comment in [post valueForKey:@"comments"])
		{
			NSString *text = [comment valueForKey:@"text"];
			NSLog(@"%@", text);
			STAssertNotNil(text, nil);
		}
	}
}

- (void)testInsertAndDeletePerson
{
	NSError *__autoreleasing error = nil;
	NSManagedObject *person = [NSEntityDescription insertNewObjectForEntityForName:@"Person" inManagedObjectContext:[self context]];
	[person setValue:@"Roy Ratcliffe" forKey:@"name"];
	BOOL yes = [[self context] save:&error];
	STAssertNotNil(person, nil);
	STAssertTrue(yes, nil);
	STAssertNil(error, nil);
	
	[[self context] deleteObject:person];
	yes = [[self context] save:&error];
	STAssertTrue(yes, nil);
	STAssertNil(error, nil);
}

- (void)testUpdatePerson
{
	NSError *__autoreleasing error = nil;
	
	NSManagedObject *person = [NSEntityDescription insertNewObjectForEntityForName:@"Person" inManagedObjectContext:[self context]];
	BOOL yes = [[self context] save:&error];
	STAssertNotNil(person, nil);
	STAssertTrue(yes, nil);
	STAssertNil(error, nil);
	
	[person setValue:@"Roy Ratcliffe" forKey:@"name"];
	yes = [[self context] save:&error];
	STAssertTrue(yes, nil);
	STAssertNil(error, nil);
}

- (void)testOnePostToManyComments
{
	// What happens when you instantiate two entities and wire them up entirely
	// at the client side first? Test it! Create a post with one
	// comment. Construct the post, comment and their relationship within the
	// client at first. Then save the context in order to transfer the objects
	// and their relationship to the remote server. Thereafter, throw away the
	// comment and refetch the comment by dereferencing the post's "comments"
	// relationship.
	NSError *__autoreleasing error = nil;
	NSManagedObject *post;
	
	@autoreleasepool {
		post = [NSEntityDescription insertNewObjectForEntityForName:@"Post" inManagedObjectContext:[self context]];
		NSManagedObject *comment = [NSEntityDescription insertNewObjectForEntityForName:@"Comment" inManagedObjectContext:[self context]];
		STAssertNotNil(post, nil);
		STAssertNotNil(comment, nil);
		
		// Set up attributes for the post and the comment.
		[post setValue:@"De finibus bonorum et malorum" forKey:@"title"];
		[post setValue:@"Non eram nescius…" forKey:@"body"];
		[comment setValue:@"Quae cum dixisset…" forKey:@"text"];
		
		// Form the one-post-to-many-comments association.
		[comment setValue:post forKey:@"post"];
		
		// Send it all to the server.
		STAssertTrue([[self context] save:&error], nil);
		STAssertNil(error, nil);
	}
	
	@autoreleasepool {
		NSMutableArray *comments = [NSMutableArray array];
		for (NSManagedObject *comment in [post valueForKey:@"comments"])
		{
			[comments addObject:[comment valueForKey:@"text"]];
		}
		STAssertFalse([comments count] == 0, nil);
		STAssertTrue([[comments objectAtIndex:0] rangeOfString:@"Quae cum dixisset…"].location != NSNotFound, nil);
	}
}

- (void)testOnePostToManyCommentsPartiallySaved
{
	NSError *__autoreleasing error = nil;
	NSManagedObject *post;
	
	@autoreleasepool {
		// Send the post to the server. This results in one POST request.
		post = [NSEntityDescription insertNewObjectForEntityForName:@"Post" inManagedObjectContext:[self context]];
		[post setValue:@"De finibus bonorum et malorum" forKey:@"title"];
		[post setValue:@"Non eram nescius…" forKey:@"body"];
		STAssertNotNil(post, nil);
		STAssertTrue([[self context] save:&error], nil);
		STAssertNil(error, nil);
		
		// Send the comment to the server. This results in a second POST request.
		NSManagedObject *comment = [NSEntityDescription insertNewObjectForEntityForName:@"Comment" inManagedObjectContext:[self context]];
		[comment setValue:@"Quae cum dixisset…" forKey:@"text"];
		STAssertNotNil(comment, nil);
		STAssertTrue([[self context] save:&error], nil);
		STAssertNil(error, nil);
		
		// Send the relationship to the server. This results in a GET request
		// for the comment and for the post. This always happens because
		// insertion of objects always evicts the resource from the resource
		// cache. The server alters attributes when creating and updating. POST
		// requests therefore desynchronise server and client. Core Data then
		// asks for all the post's comments, another GET request. Finally, a PUT
		// request for the comment saves the new association.
		//
		// As a side effect, an unwanted one, Core Data also marks the post as
		// modified and issues an update for it.
		[comment setValue:post forKey:@"post"];
		STAssertTrue([[self context] save:&error], nil);
		STAssertNil(error, nil);
		
	}
	
	@autoreleasepool {
		NSMutableArray *comments = [NSMutableArray array];
		for (NSManagedObject *comment in [post valueForKey:@"comments"])
		{
			[comments addObject:[comment valueForKey:@"text"]];
		}
		STAssertFalse([comments count] == 0, nil);
		STAssertTrue([[comments objectAtIndex:0] rangeOfString:@"Quae cum dixisset…"].location != NSNotFound, nil);
	}
}

@end
