//
//  CoinbaseETHFetcher.m
//  btcbar
//

#import "CoinbaseETHFetcher.h"

@implementation CoinbaseETHFetcher

- (id)init
{
    if (self = [super init])
    {
        // Menu Item Name
        self.ticker_menu = @"ETH/USD (Coinbase)";

        // Website location
        self.url = @"https://coinbase.com/";

        // Immediately request first update
        [self requestUpdate];
    }

    return self;
}

// Override Ticker setter to trigger status item update
- (void)setTicker:(NSString *)tickerString
{
    // Update the ticker value
    _ticker = tickerString;

    // Trigger notification to update ticker
    [[NSNotificationCenter defaultCenter] postNotificationName:@"btcbar_ticker_update" object:self];
}

// Initiates an asyncronous HTTP connection
- (void)requestUpdate
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://api.coinbase.com/v2/prices/ETH-USD/buy"]];

    // Set the Coinbase API version as HTTP header
    [request addValue:@"2015-04-08" forHTTPHeaderField:@"CB-VERSION"];
    // Set the request's user agent
    [request addValue:@"btcbar/2.0 (CoinbaseETHFetcher)" forHTTPHeaderField:@"User-Agent"];

    // Initialize a connection from our request
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];

    // Go go go
    [connection start];
}

// Initializes data storage on request response
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    self.responseData = [[NSMutableData alloc] init];
}

// Appends response data
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self.responseData appendData:data];
}

// Indiciate no caching
- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
    return nil;
}

// Parse data after load
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    // Parse the JSON into results
    NSError *jsonParsingError = nil;
    NSDictionary *results = [[NSDictionary alloc] init];
    results = [NSJSONSerialization JSONObjectWithData:self.responseData options:0 error:&jsonParsingError];

    // Results parsed successfully from JSON
    if(results)
    {
        // Get API status
        NSString *resultsStatus = [results valueForKeyPath:@"data.amount"];

        // If API call succeeded update the ticker...
        if(resultsStatus)
        {
            NSDecimalNumber *resultsStatusNumber = [NSDecimalNumber decimalNumberWithString:resultsStatus];
            NSNumberFormatter *currencyStyle = [[NSNumberFormatter alloc] init];
            currencyStyle.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
            currencyStyle.numberStyle = NSNumberFormatterCurrencyStyle;
            self.ticker = [currencyStyle stringFromNumber:resultsStatusNumber];
        }
        // Otherwise log an error...
        else
        {
            self.error = [NSError errorWithDomain:@"mn.frd.cryptobar" code:0 userInfo:[NSDictionary dictionaryWithObjectsAndKeys: @"API Error", NSLocalizedDescriptionKey, @"The JSON received did not contain a result or the API returned an error.", NSLocalizedFailureReasonErrorKey, nil]];
            self.ticker = nil;
        }
    }
    // JSON parsing failed
    else
    {
        self.error = [NSError errorWithDomain:@"mn.frd.cryptobar" code:0 userInfo:[NSDictionary dictionaryWithObjectsAndKeys: @"JSON Error", NSLocalizedDescriptionKey, @"Could not parse the JSON returned.", NSLocalizedFailureReasonErrorKey, nil]];
        self.ticker = nil;
    }
}

// HTTP request failed
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    self.error = [NSError errorWithDomain:@"mn.frd.cryptobar" code:0 userInfo:[NSDictionary dictionaryWithObjectsAndKeys: @"Connection Error", NSLocalizedDescriptionKey, @"Could not connect to Coinbase.", NSLocalizedFailureReasonErrorKey, nil]];
    self.ticker = nil;
}

@end
