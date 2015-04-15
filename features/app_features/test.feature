Feature: Test Feature for RESTful API Test
  In order to ensure quality
  As a QA  I want to be able to execute functional tests against my application's RESTful API 

  Background: 
    Given I set the following configuration for the tests:
      | API_ENDPOINT  | https://localhost:8080/v1/api|
      | TESTPARAM1    | test1                        |

Scenario: GET - readCampaigns - true/true and includeFlights/false
    Given I set the parameters for request as:
      | Cookie             | valid      |
      | TESTPARMA2         | test2      |
    And I send GET request to "/someendpoint/{queryparam1}"
    Then the response status should be "200"
    Then the JSON response should have "$.data[0].good" with the text "true"

