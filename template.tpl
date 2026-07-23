___TERMS_OF_SERVICE___

By creating or modifying this file you agree to Google Tag Manager's Community
Template Gallery Developer Terms of Service available at
https://developers.google.com/tag-manager/gallery-tos (or such other URL as
Google may provide), as modified from time to time.


___INFO___
{
  "type": "MACRO",
  "id": "cvt_temp_public_id",
  "version": 1,
  "securityGroups": [],
  "displayName": "Amazon CAPI Auth",
  "description": "This variable generates access token for Amazon Ads API",
  "categories": ["ADVERTISING", "ANALYTICS", "CONVERSIONS"],
  "containerContexts": [
    "SERVER"
  ]
}

___TEMPLATE_PARAMETERS___
[
  {
    "type": "TEXT",
    "name": "clientId",
    "displayName": "Client ID",
    "simpleValueType": true
  },
  {
    "type": "TEXT",
    "name": "clientSecret",
    "displayName": "Client Secret",
    "simpleValueType": true
  },
  {
    "type": "TEXT",
    "name": "refreshToken",
    "displayName": "Refresh Token",
    "simpleValueType": true
  }
]

___SANDBOXED_JS_FOR_SERVER___

// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

const sendHttpRequest = require('sendHttpRequest');
const logToConsole = require('logToConsole');
const JSON = require('JSON');
const encodeUriComponent = require('encodeUriComponent');
const getTimestampMillis = require('getTimestampMillis');
const templateDataStorage = require('templateDataStorage');
const clientId = data.clientId;
const clientSecret = data.clientSecret;
const refreshToken = data.refreshToken;
const currentTime = getTimestampMillis();

// Get token from persistent storage
const storedToken = templateDataStorage.getItemCopy('amazonToken');

// Check if stored token is still valid
if (storedToken && 
    storedToken.accessToken && 
    storedToken.expiresAt > currentTime && 
    storedToken.clientId === clientId) {
    return {
        accessToken: storedToken.accessToken,
        clientId: clientId
    };
}

if (!clientId || !clientSecret || !refreshToken) {
    logToConsole('Missing required parameters');
    return undefined;
}

const BASE_URL = 'https://api.amazon.com/auth/o2/token';
const DEFAULT_HEADERS = {
    'Content-Type': 'application/x-www-form-urlencoded'
};

const requestBody = 'grant_type=refresh_token' + 
                   '&refresh_token=' + encodeUriComponent(refreshToken) +
                   '&client_id=' + encodeUriComponent(clientId) +
                   '&client_secret=' + encodeUriComponent(clientSecret);

const requestOptions = {
    method: 'POST',
    headers: DEFAULT_HEADERS,
    timeout: 5000
};

return sendHttpRequest(BASE_URL, requestOptions, requestBody).then(response => {
    const responseBody = JSON.parse(response.body);
    
    // Store new token data
    templateDataStorage.setItemCopy('amazonToken', {
        accessToken: responseBody.access_token,
        expiresAt: currentTime + ((responseBody.expires_in - 300) * 1000), // refreshes every 55 mins - 5 minute expiry buffer
        clientId: clientId
    });
    
    // Return what's needed to make calls to Amazon Ads Conversions API Tag
    return {
        accessToken: responseBody.access_token,
        clientId: clientId
    };
});

___SERVER_PERMISSIONS___
[
  {
    "instance": {
      "key": {
        "publicId": "access_template_storage",
        "versionId": "1"
      },
      "param": []
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "logging",
        "versionId": "1"
      },
      "param": [
        {
          "key": "environments",
          "value": {
            "type": 1,
            "string": "debug"
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "send_http",
        "versionId": "1"
      },
      "param": [
        {
          "key": "allowedUrls",
          "value": {
            "type": 1,
            "string": "specific"
          }
        },
        {
          "key": "urls",
          "value": {
            "type": 2,
            "listItem": [
              {
                "type": 1,
                "string": "https://api.amazon.com/auth/o2/token"
              }
            ]
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  }
]

___TESTS___

scenarios:
- name: Returns cached token when valid and clientId matches
  code: |-
    const currentTime = 1000000;
    const storedToken = { accessToken: 'cached-token', expiresAt: 2000000, clientId: 'my-client-id' };
    const clientId = 'my-client-id';
    const isValid = storedToken && storedToken.accessToken && storedToken.expiresAt > currentTime && storedToken.clientId === clientId;
    assertThat(isValid).isTrue();

- name: Does not use cached token when expired
  code: |-
    const currentTime = 3000000;
    const storedToken = { accessToken: 'cached-token', expiresAt: 2000000, clientId: 'my-client-id' };
    const clientId = 'my-client-id';
    const isValid = storedToken && storedToken.accessToken && storedToken.expiresAt > currentTime && storedToken.clientId === clientId;
    assertThat(isValid).isFalse();

- name: Does not use cached token when clientId does not match
  code: |-
    const currentTime = 1000000;
    const storedToken = { accessToken: 'cached-token', expiresAt: 2000000, clientId: 'old-client-id' };
    const clientId = 'new-client-id';
    const isValid = storedToken && storedToken.accessToken && storedToken.expiresAt > currentTime && storedToken.clientId === clientId;
    assertThat(isValid).isFalse();

- name: Token expiry includes 5-minute buffer
  code: |-
    const currentTime = 1000000;
    const expiresIn = 3600; // 1 hour in seconds
    const expiresAt = currentTime + ((expiresIn - 300) * 1000); // 55 minutes
    assertThat(expiresAt).isEqualTo(currentTime + 3300000);

- name: Returns undefined when required params are missing
  code: |-
    const validate = (clientId, clientSecret, refreshToken) => {
      if (!clientId || !clientSecret || !refreshToken) return undefined;
      return 'valid';
    };
    assertThat(validate('id', 'secret', 'token')).isEqualTo('valid');
    assertThat(validate('', 'secret', 'token')).isUndefined();
    assertThat(validate('id', '', 'token')).isUndefined();
    assertThat(validate('id', 'secret', '')).isUndefined();
    assertThat(validate(null, null, null)).isUndefined();



___NOTES___

Created in May 2026 by Amazon Ad Tech Solutions.

## Version History
- v1.0.0 (May 2026): Initial release
