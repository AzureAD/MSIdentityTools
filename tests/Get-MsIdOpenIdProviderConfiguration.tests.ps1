[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string] $ModulePath = "..\src\*.psd1"
)

BeforeAll {
    $PSModule = Import-Module $ModulePath -Force -PassThru
}

## Perform Tests
Describe 'Get-MsIdOpenIdProviderConfiguration' {
    
    BeforeAll {
        Mock -ModuleName $PSModule.Name Invoke-RestMethod { ConvertFrom-Json '{"token_endpoint":"https://login.microsoftonline.com/common/oauth2/token","token_endpoint_auth_methods_supported":["client_secret_post","private_key_jwt","client_secret_basic"],"jwks_uri":"https://login.microsoftonline.com/common/discovery/keys","response_modes_supported":["query","fragment","form_post"],"subject_types_supported":["pairwise"],"id_token_signing_alg_values_supported":["RS256"],"response_types_supported":["code","id_token","code id_token","token id_token","token"],"scopes_supported":["openid"],"issuer":"https://sts.windows.net/{tenantid}/","microsoft_multi_refresh_token":true,"authorization_endpoint":"https://login.microsoftonline.com/common/oauth2/authorize","device_authorization_endpoint":"https://login.microsoftonline.com/common/oauth2/devicecode","http_logout_supported":true,"frontchannel_logout_supported":true,"end_session_endpoint":"https://login.microsoftonline.com/common/oauth2/logout","claims_supported":["sub","iss","cloud_instance_name","cloud_instance_host_name","cloud_graph_host_name","msgraph_host","aud","exp","iat","auth_time","acr","amr","nonce","email","given_name","family_name","nickname"],"check_session_iframe":"https://login.microsoftonline.com/common/oauth2/checksession","userinfo_endpoint":"https://login.microsoftonline.com/common/openid/userinfo","kerberos_endpoint":"https://login.microsoftonline.com/common/kerberos","tenant_region_scope":null,"cloud_instance_name":"microsoftonline.com","cloud_graph_host_name":"graph.windows.net","msgraph_host":"graph.microsoft.com","rbac_url":"https://pas.windows.net"}' } -ParameterFilter { $Uri.AbsoluteUri.EndsWith('/.well-known/openid-configuration') } -Verifiable
        Mock -ModuleName $PSModule.Name Invoke-RestMethod { ConvertFrom-Json '{"keys":[{"kty":"RSA","use":"sig","kid":"nOo3ZDrODXEK1jKWhXslHR_KXEg","x5t":"nOo3ZDrODXEK1jKWhXslHR_KXEg","n":"oaLLT9hkcSj2tGfZsjbu7Xz1Krs0qEicXPmEsJKOBQHauZ_kRM1HdEkgOJbUznUspE6xOuOSXjlzErqBxXAu4SCvcvVOCYG2v9G3-uIrLF5dstD0sYHBo1VomtKxzF90Vslrkn6rNQgUGIWgvuQTxm1uRklYFPEcTIRw0LnYknzJ06GC9ljKR617wABVrZNkBuDgQKj37qcyxoaxIGdxEcmVFZXJyrxDgdXh9owRmZn6LIJlGjZ9m59emfuwnBnsIQG7DirJwe9SXrLXnexRQWqyzCdkYaOqkpKrsjuxUj2-MHX31FqsdpJJsOAvYXGOYBKJRjhGrGdONVrZdUdTBQ","e":"AQAB","x5c":["MIIDBTCCAe2gAwIBAgIQN33ROaIJ6bJBWDCxtmJEbjANBgkqhkiG9w0BAQsFADAtMSswKQYDVQQDEyJhY2NvdW50cy5hY2Nlc3Njb250cm9sLndpbmRvd3MubmV0MB4XDTIwMTIyMTIwNTAxN1oXDTI1MTIyMDIwNTAxN1owLTErMCkGA1UEAxMiYWNjb3VudHMuYWNjZXNzY29udHJvbC53aW5kb3dzLm5ldDCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAKGiy0/YZHEo9rRn2bI27u189Sq7NKhInFz5hLCSjgUB2rmf5ETNR3RJIDiW1M51LKROsTrjkl45cxK6gcVwLuEgr3L1TgmBtr/Rt/riKyxeXbLQ9LGBwaNVaJrSscxfdFbJa5J+qzUIFBiFoL7kE8ZtbkZJWBTxHEyEcNC52JJ8ydOhgvZYykete8AAVa2TZAbg4ECo9+6nMsaGsSBncRHJlRWVycq8Q4HV4faMEZmZ+iyCZRo2fZufXpn7sJwZ7CEBuw4qycHvUl6y153sUUFqsswnZGGjqpKSq7I7sVI9vjB199RarHaSSbDgL2FxjmASiUY4RqxnTjVa2XVHUwUCAwEAAaMhMB8wHQYDVR0OBBYEFI5mN5ftHloEDVNoIa8sQs7kJAeTMA0GCSqGSIb3DQEBCwUAA4IBAQBnaGnojxNgnV4+TCPZ9br4ox1nRn9tzY8b5pwKTW2McJTe0yEvrHyaItK8KbmeKJOBvASf+QwHkp+F2BAXzRiTl4Z+gNFQULPzsQWpmKlz6fIWhc7ksgpTkMK6AaTbwWYTfmpKnQw/KJm/6rboLDWYyKFpQcStu67RZ+aRvQz68Ev2ga5JsXlcOJ3gP/lE5WC1S0rjfabzdMOGP8qZQhXk4wBOgtFBaisDnbjV5pcIrjRPlhoCxvKgC/290nZ9/DLBH3TbHk8xwHXeBAnAjyAqOZij92uksAv7ZLq4MODcnQshVINXwsYshG1pQqOLwMertNaY5WtrubMRku44Dw7R"]},{"kty":"RSA","use":"sig","kid":"l3sQ-50cCH4xBVZLHTGwnSR7680","x5t":"l3sQ-50cCH4xBVZLHTGwnSR7680","n":"sfsXMXWuO-dniLaIELa3Pyqz9Y_rWff_AVrCAnFSdPHa8__Pmkbt_yq-6Z3u1o4gjRpKWnrjxIh8zDn1Z1RS26nkKcNg5xfWxR2K8CPbSbY8gMrp_4pZn7tgrEmoLMkwfgYaVC-4MiFEo1P2gd9mCdgIICaNeYkG1bIPTnaqquTM5KfT971MpuOVOdM1ysiejdcNDvEb7v284PYZkw2imwqiBY3FR0sVG7jgKUotFvhd7TR5WsA20GS_6ZIkUUlLUbG_rXWGl0YjZLS_Uf4q8Hbo7u-7MaFn8B69F6YaFdDlXm_A0SpedVFWQFGzMsp43_6vEzjfrFDJVAYkwb6xUQ","e":"AQAB","x5c":["MIIDBTCCAe2gAwIBAgIQWPB1ofOpA7FFlOBk5iPaNTANBgkqhkiG9w0BAQsFADAtMSswKQYDVQQDEyJhY2NvdW50cy5hY2Nlc3Njb250cm9sLndpbmRvd3MubmV0MB4XDTIxMDIwNzE3MDAzOVoXDTI2MDIwNjE3MDAzOVowLTErMCkGA1UEAxMiYWNjb3VudHMuYWNjZXNzY29udHJvbC53aW5kb3dzLm5ldDCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBALH7FzF1rjvnZ4i2iBC2tz8qs/WP61n3/wFawgJxUnTx2vP/z5pG7f8qvumd7taOII0aSlp648SIfMw59WdUUtup5CnDYOcX1sUdivAj20m2PIDK6f+KWZ+7YKxJqCzJMH4GGlQvuDIhRKNT9oHfZgnYCCAmjXmJBtWyD052qqrkzOSn0/e9TKbjlTnTNcrIno3XDQ7xG+79vOD2GZMNopsKogWNxUdLFRu44ClKLRb4Xe00eVrANtBkv+mSJFFJS1Gxv611hpdGI2S0v1H+KvB26O7vuzGhZ/AevRemGhXQ5V5vwNEqXnVRVkBRszLKeN/+rxM436xQyVQGJMG+sVECAwEAAaMhMB8wHQYDVR0OBBYEFLlRBSxxgmNPObCFrl+hSsbcvRkcMA0GCSqGSIb3DQEBCwUAA4IBAQB+UQFTNs6BUY3AIGkS2ZRuZgJsNEr/ZEM4aCs2domd2Oqj7+5iWsnPh5CugFnI4nd+ZLgKVHSD6acQ27we+eNY6gxfpQCY1fiN/uKOOsA0If8IbPdBEhtPerRgPJFXLHaYVqD8UYDo5KNCcoB4Kh8nvCWRGPUUHPRqp7AnAcVrcbiXA/bmMCnFWuNNahcaAKiJTxYlKDaDIiPN35yECYbDj0PBWJUxobrvj5I275jbikkp8QSLYnSU/v7dMDUbxSLfZ7zsTuaF2Qx+L62PsYTwLzIFX3M8EMSQ6h68TupFTi5n0M2yIXQgoRoNEDWNJZ/aZMY/gqT02GQGBWrh+/vJ"]}]}' } -ParameterFilter { !$Uri.AbsoluteUri.EndsWith('/.well-known/openid-configuration') } -Verifiable

        $TestCases = @(
            @{ Issuer = 'https://login.microsoftonline.com/common'; Expected = 'https://login.microsoftonline.com/common/.well-known/openid-configuration'; ExpectedKeys = 'https://login.microsoftonline.com/common/discovery/keys' }
            @{ Issuer = 'https://login.microsoftonline.com/common/'; Expected = 'https://login.microsoftonline.com/common//.well-known/openid-configuration'; ExpectedKeys = 'https://login.microsoftonline.com/common/discovery/keys' }
        )
    }

    Context 'Issuer: <Issuer>' -Foreach @(
        @{ Issuer = 'https://login.microsoftonline.com/common'; Expected = 'https://login.microsoftonline.com/common/.well-known/openid-configuration'; ExpectedKeys = 'https://login.microsoftonline.com/common/discovery/keys' }
        @{ Issuer = 'https://login.microsoftonline.com/common/'; Expected = 'https://login.microsoftonline.com/common//.well-known/openid-configuration'; ExpectedKeys = 'https://login.microsoftonline.com/common/discovery/keys' }
    ) {
        It 'Positional Parameter' {
            $Output = Get-MsIdOpenIdProviderConfiguration $Issuer
            $Output | Should -BeOfType [pscustomobject]
            $script:jwks_uri = $Output.jwks_uri
            #$Output.jwks_uri | Should -Be $ExpectedKeys
            Should -Invoke Invoke-RestMethod -ModuleName $PSModule.Name -ParameterFilter {
                $Uri -eq $Expected
            }
        }

        It 'Pipeline Input' {
            $Output = $Issuer | Get-MsIdOpenIdProviderConfiguration
            $Output | Should -BeOfType [pscustomobject]
            $script:jwks_uri = $Output.jwks_uri
            #$Output.jwks_uri | Should -Be $ExpectedKeys
            Should -Invoke Invoke-RestMethod -ModuleName $PSModule.Name -ParameterFilter {
                $Uri -eq $Expected
            }
        }

        It 'Keys: Positional Parameter' {
            $Output = Get-MsIdOpenIdProviderConfiguration $Issuer -Keys
            $Output | Should -BeOfType [pscustomobject]
            Should -Invoke Invoke-RestMethod -ModuleName $PSModule.Name -ParameterFilter {
                $Uri -eq $jwks_uri
                #$Uri -eq $ExpectedKeys
            }
        }

        It 'Keys: Pipeline Input' {
            $Output = $Issuer | Get-MsIdOpenIdProviderConfiguration -Keys
            $Output | Should -BeOfType [pscustomobject]
            Should -Invoke Invoke-RestMethod -ModuleName $PSModule.Name -ParameterFilter {
                $Uri -eq $jwks_uri
                #$Uri -eq $ExpectedKeys
            }
        }
    }

    Context 'Multiple Input' {
        It 'Pipeline Input' {
            $Output = $TestCases.Issuer | Get-MsIdOpenIdProviderConfiguration
            $Output | Should -BeOfType [pscustomobject]
            $Output | Should -HaveCount $TestCases.Count
            for ($i = 0; $i -lt $TestCases.Count; $i++) {
                #$Value.jwks_uri | Should -Be $ExpectedKeys
                Should -Invoke Invoke-RestMethod -ModuleName $PSModule.Name -ParameterFilter {
                    $Uri -eq $TestCases[$i].Expected
                }
            }
        }

        # It 'Keys: Pipeline Input' {
        #     $Output = $TestCases.Issuer | Get-MsIdOpenIdProviderConfiguration -Keys
        #     $Output | Should -BeOfType [pscustomobject]
        #     $Output | Should -HaveCount $TestCases.Count
        #     for ($i = 0; $i -lt $Output.Count; $i++) {
        #         Should -Invoke Invoke-RestMethod -ModuleName $PSModule.Name -ParameterFilter {
        #             $Uri -eq $TestCases[$i].ExpectedKeys
        #         }
        #     }
        # }
    }
}
