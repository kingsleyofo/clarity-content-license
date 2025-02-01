# Content License Manager

A blockchain-based content licensing system built on the Stacks blockchain that allows:

- Content creators to register and monetize their content
- Users to purchase time-based licenses for content
- Automated license verification
- License management and tracking
- Subscription-based licensing with auto-renewal

## Features

- Register new content with customizable pricing and license types
- Configure multiple subscription periods (1 month, 3 months, 12 months etc)
- Purchase content licenses with automated payments
- Enable auto-renewal for subscription licenses
- Check license validity
- Update content pricing
- Time-based license expiration
- Renew existing licenses

## Usage

The contract provides the following main functions:

- register-content: Register new content with price, license type and subscription periods
- purchase-license: Purchase a license for specific content with optional auto-renewal
- has-valid-license: Check if an address has a valid license
- get-content-details: Get details about registered content
- update-price: Update the price of registered content
- get-license-details: Get details about a specific license
- renew-license: Renew an existing auto-renewable license

## Implementation

The system uses Clarity smart contracts to manage:
- Content registration and ownership
- License purchases and tracking
- Automated payments
- License verification
- Subscription management and auto-renewals
