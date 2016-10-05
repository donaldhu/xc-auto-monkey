# xc-auto-monkey
Blazingly fast monkey to stress test your iOS application

# Installation
1. In Xcode, create a new target with template `iOS UI Testing Bundle` (`File → New → Target → iOS UI Testing Bundle`)
2. Copy [MonkeyUITests.m](https://github.com/donaldhu/xc-auto-monkey/blob/master/MonkeyUITests/MonkeyUITests.m) into the new UI test target.
3. Run the monkey test by running your project tests (`Command(⌘) + U`)

# Configuration
At the top of MonkeyUITests.m, there are some configuration settings:

```obj-c
static NSTimeInterval const XCMonkeyEventDelay = 0.1;  // In seconds

static NSUInteger const XCMonkeyEventWeightTap = 10;
static NSUInteger const XCMonkeyEventWeightPan = 10;
```
