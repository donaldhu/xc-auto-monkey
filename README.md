# XC AutoMonkey
Blazingly fast monkey to stress test your iOS application

# Installation
1. In Xcode, create a new target with template `iOS UI Testing Bundle` (`File → New → Target → iOS UI Testing Bundle`)
<img alt="Step 1" src="https://raw.github.com/donaldhu/xc-auto-monkey/master/readme_images/add_monkey_target.png">
2. Add [MonkeyUITests.m](https://github.com/donaldhu/xc-auto-monkey/blob/master/MonkeyUITests.m) into the new UI test target.
<img alt="Step 2a" src="https://raw.github.com/donaldhu/xc-auto-monkey/master/readme_images/add_monkey_test.png" height=300>
3. Run the monkey test by running your project tests (`Command(⌘) + U`)

# Configuration
At the top of MonkeyUITests.m, there are some configuration settings:

```obj-c
static NSTimeInterval const XCMonkeyEventDelay = 0.1;  // In seconds

// Test pass conditions
// Set the value to 0 if you do not want to use the pass condition
// The monkey test will pass if ANY of the conditions are met

static NSUInteger const XCMonkeyEventsCount = 100000;
static NSTimeInterval const XCMonkeyDuration = 60 * 60 * 5; // In seconds

// Weights control the probability of the monkey performing an action
// A heigher weights results in a higher probability

static NSUInteger const XCMonkeyEventWeightTap = 500;
static NSUInteger const XCMonkeyEventWeightPan = 50;
static NSUInteger const XCMonkeyEventWeightPinchIn = 50;
static NSUInteger const XCMonkeyEventWeightPinchOut = 50;
static NSUInteger const XCMonkeyEventWeightBackgroundAndForeground = 1;
```

# Coming Soon
* New gestures and events
  * Orientation
  * Volume up and down
  * Multiple taps
  * Lock
* Improved device support for not triggering control and notification centers
