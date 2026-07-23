# Amazon CAPI Auth — Server-Side Variable Template for Google Tag Manager

This Google Tag Manager server-side variable template generates and caches OAuth access tokens for the Amazon Ads API, for use with the [Amazon Events API Tag](https://github.com/amzn/ads-events-api-gtm-tag).

## Configuration

After importing the template, create a new variable using the Amazon CAPI Auth template. The variable configuration includes:

- **Client ID**: Your Amazon Ads API client ID
- **Client Secret**: Your Amazon Ads API client secret
- **Refresh Token**: Your Amazon Ads API refresh token

To generate these credentials, register your application with the Amazon Ads API and follow the [Login with Amazon](https://advertising.amazon.com/API/docs/en-us/guides/get-started/using-postman-collection) guide to obtain a refresh token.

## Usage

1. Create a new variable in your GTM server container using the **Amazon CAPI Auth** template.
2. Enter your Client ID, Client Secret, and Refresh Token.
3. Save the variable.
4. In the **Amazon Events API Tag**, select this variable in the **Amazon CAPI Auth Variable** field.

The variable handles:

- Fetching a new access token via the Amazon Ads OAuth endpoint (`https://api.amazon.com/auth/o2/token`)
- Caching the token for 55 minutes (with a 5-minute expiry buffer) in GTM template storage
- Automatically refreshing when the cached token expires
- Returning the access token and client ID to the tag on each request

## Support

For issues or questions, please open an issue in this repository.

## Security

All credentials and access tokens are stored and processed entirely within your GTM server container. They are never exposed to client-side code or sent to the browser.

See CONTRIBUTING for more information.

## License

Apache 2.0 — see [LICENSE](LICENSE)
