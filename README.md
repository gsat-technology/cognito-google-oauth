
Demonstrates how to create a public S3 bucket (website) and allow a simple sign-in using Google OAuth. The sign in process creates an identity in Cognito.

(WIP)

# Google OAuth setup
1. goto google developers console
2. create new project
3. call it something like 'cognitodemo'
4. goto 'Google APIs' tab
5. Click 'Google+ APIs' (Under 'Social APIs' heading), click 'enable'
6. Go to 'Credentials'
7. Click 'Create Credentials' and select 'OAuth Client ID' option
8. Click 'Configure concent screen' button
9. Add the 'Product Name' e.g. 'CognitoDemo'
10. Choose Application type: 'Web Application'
11. Give it a name e.g 'CognitoDemo'
12. In the 'Authorised Javascript Origins' field, enter the S3 website FQDN
13. Click 'create'
14. Copy the client ID
15. Paste client ID in index.html



