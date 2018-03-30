<# It is important to test our test. It really is. 
 # (http://jakubjares.com/2017/12/07/testing-your-environment-tests/)
 #
 #   To be able to do it with Pester one has to keep the test definition and the assertion 
 # in separate files. Write a new test, or modifying an existing one typically involves 
 # modifications to the three related files:
 #
 # /checks/Database.Assertions.ps1                          - where the assertions are defined
 # /checks/Database.Tests.ps1                               - where the assertions are used to check stuff
 # /tests/checks/Database.Assetions.Tests.ps1 (this file)   - where the assertions are unit tests
 #>

$commandname = $MyInvocation.MyCommand.Name.Replace(".Tests.ps1", "")
Write-Host -Object "Running $PSCommandpath" -ForegroundColor Cyan
. "$PSScriptRoot/../../internal/functions/Set-DatabaseForIntegrationTesting.ps1"
. "$PSScriptRoot/../../checks/Database.Assertions.ps1"

Describe "Testing Auto Close Assertion" -Tags AutoClose {
    Mock Get-DbcConfigValue { return "True" } -ParameterFilter { $Name -like "policy.database.autoclose" }

    Context "Test config value conversion" {
        It "'True' string is $true" {
            Mock Get-DbcConfigValue { return "True" } -ParameterFilter { $Name -like "policy.database.autoclose" }
            (Get-SettingsForAutoCloseCheck).AutoClose | Should -BeTrue
        }

        It "'1' string is $true" {
            Mock Get-DbcConfigValue { return "1" } -ParameterFilter { $Name -like "policy.database.autoclose" }
            (Get-SettingsForAutoCloseCheck).AutoClose | Should -BeTrue
        }

        It "'on' string is $true" {
            Mock Get-DbcConfigValue { return "On" } -ParameterFilter { $Name -like "policy.database.autoclose" }
            (Get-SettingsForAutoCloseCheck).AutoClose | Should -BeTrue
        }

        It "'yes' string is $true" {
            Mock Get-DbcConfigValue { return "yes" } -ParameterFilter { $Name -like "policy.database.autoclose" }
            (Get-SettingsForAutoCloseCheck).AutoClose | Should -BeTrue
        }

        It "'False' string is $true" {
            Mock Get-DbcConfigValue { return "False" } -ParameterFilter { $Name -like "policy.database.autoclose" }
            (Get-SettingsForAutoCloseCheck).AutoClose | Should -BeFalse
        }

        It "'0' string is $true" {
            Mock Get-DbcConfigValue { return "0" } -ParameterFilter { $Name -like "policy.database.autoclose" }
            (Get-SettingsForAutoCloseCheck).AutoClose | Should -BeFalse
        }

        It "'off' string is $true" {
            Mock Get-DbcConfigValue { return "off" } -ParameterFilter { $Name -like "policy.database.autoclose" }
            (Get-SettingsForAutoCloseCheck).AutoClose | Should -BeFalse
        }

        It "'no' string is $true" {
            Mock Get-DbcConfigValue { return "no" } -ParameterFilter { $Name -like "policy.database.autoclose" }
            (Get-SettingsForAutoCloseCheck).AutoClose | Should -BeFalse
        }

        It "policy.database.autoclose set to random string should thow an exception" {
            Mock Get-DbcConfigValue { return "somerandomvalue" } -ParameterFilter { $Name -like "policy.database.autoclose" }
            { Get-SettingsForAutoCloseCheck } | Should -Throw
        }
    }

    Context "Tests with expected Auto Close set to true" {
        Mock Get-DbcConfigValue { return "True" } -ParameterFilter { $Name -like "policy.database.autoclose" }

        $testSettings = Get-SettingsForAutoCloseCheck 

        It "The test should pass when the database's auto close is set to true" {
            @{
                AutoClose = $true
            } | 
            Assert-AutoClose -With $testSettings
        }

        It "The test should fail when the database's auto close is set to false" {
            {
                @{
                    AutoClose = $false 
                } | 
                Assert-AutoClose -With $testSettings
            } | Should -Throw 
        }
    }

    Context "Tests with expected Auto Close set to false" {
        Mock Get-DbcConfigValue { return "False" } -ParameterFilter { $Name -like "policy.database.autoclose" }

        $testSettings = Get-SettingsForAutoCloseCheck 

        It "The test should pass when the database's auto close is set to true" {
            @{
                AutoClose = $false 
            } | 
            Assert-AutoClose -With $testSettings
        }

        It "The test should fail when the database's auto close is set to false" {
            {
                @{
                    AutoClose = $true
                } | 
                Assert-AutoClose -With $testSettings
            } | Should -Throw 
        }
    }
}

Describe "Testing Page Verify Assertions" -Tags PageVerify {
    Context "Test configuration" {
        $cases = @(
            @{ Option = "CHECKSUM" },
            @{ Option = "TORN_PAGE_DETECTION" },
            @{ Option = "NONE" }
        )

        It "<Option> is acceptable as policy.pageverify value" -TestCases $cases {
            param($Option) 
            Mock Get-DbcConfigValue { return $Option } -ParameterFilter { $Name -like "policy.pageverify" }
            (Get-SettingsForPageVerifyCheck).PageVerify | Should -Be $Option
        }
        
        It "Throw exception when policy.pageverify is set to unsupported option" {
            Mock Get-DbcConfigValue { return "NOT_SUPPORTED_OPTION" } -ParameterFilter { $Name -like "policy.pageverify" }
            { Get-SettingsForPageVerifyCheck } | Should -Throw 
        }
    }

    Context "Test the assert function" {
        Mock Get-DbcConfigValue { return "CHECKSUM" } -ParameterFilter { $Name -like "policy.pageverify" }

        $testSettings = Get-SettingsForPageVerifyCheck 

        It "The test should pass when the PageVerify is as configured" {
            @{
                PageVerify = "CHECKSUM"
            } | 
                Assert-PageVerify -With $testSettings 
        }

        It "The test should fail when the PageVerify is not as configured" {
            {
                @{
                    PageVerify = "NONE"
                } | 
                    Assert-PageVerify -With $testSettings
            } | Should -Throw 
        }
    }
}

Describe "Testing the $commandname checks" -Tags CheckTests, "$($commandname)CheckTests" {
    Context "Validate the database collation check" {
        Mock Get-DbcConfigValue { return "mySpecialDbWithUniqueCollation" } -ParameterFilter { $Name -like "policy.database.wrongcollation" }
        
        $testSettings = Get-SettingsForDatabaseCollactionCheck

        It "The test should pass when the database is not on the exclusion list and the collations match" {
            @{
                Database = "db1"
                ServerCollation = "collation1"
                DatabaseCollation = "collation1"
            } |
            Assert-DatabaseCollation -With $testSettings
        }

        It "The test should pass when the database is on the exclusion list and the collations do not match" {
            @{
                Database = "mySpecialDbWithUniqueCollation"
                ServerCollation = "collation1"
                DatabaseCollation = "collation2"
            } |
            Assert-DatabaseCollation -With $testSettings
        }

        It "The test should pass when the database is ReportingServer and the collations do not match" {
            @{
                Database = "mySpecialDbWithUniqueCollation"
                ServerCollation = "collation1"
                DatabaseCollation = "collation2"
            } |
            Assert-DatabaseCollation -With $testSettings
        }

        It "The test should fail when the database is not on the exclusion list and the collations do not match" {
            {
                @{
                    Database = "db1"
                    ServerCollation = "collation1"
                    DatabaseCollation = "collation2"
                } |
                Assert-DatabaseCollation -With $testSettings
            } | Should -Throw
        }

        It "The test should pass when excluded datbase collation does not matche the instance collation" {
            @{
                Database = "mySpecialDbWithUniqueCollation"
                ServerCollation = "collation1"
                DatabaseCollation = "collation2"
            } |
            Assert-DatabaseCollation -With $testSettings
        }
    }

    Context "Validate database owner is valid check" {
        Mock Get-DbcConfigValue { return "correctlogin1","correctlogin2" } -ParameterFilter { $Name -like "policy.validdbowner.name" }
        Mock Get-DbcConfigValue { return "myExcludedDb" } -ParameterFilter { $Name -like "policy.validdbowner.excludedb" }
        
        $testSettings = Get-SettingsForDatabaseOwnerIsValidCheck

        It "The test should pass when the current owner is one of the expected owners" {
            @(@{ 
                Database="db1"
                Owner = "correctlogin1" 
            }) | 
            Assert-DatabaseOwnerIsValid -With $testSettings       
        }
    
        It "The test should pass when the current owner is any of the expected owners" {
            @(@{ 
                Database="db1"
                Owner = "correctlogin2" 
            }) | 
            Assert-DatabaseOwnerIsValid -With $testSettings       
        }

        It "The test should pass even if an excluded database has an incorrect owner" {
            @(@{ 
                Database="db1"
                Owner = "correctlogin1" 
            }, @{
                Database = "myExcludedDb"
                Owner = "incorrectlogin"
            }) | 
            Assert-DatabaseOwnerIsValid -With $testSettings
        }
        
        It "The test should fail when the owner is not one of the expected ones" {
            {
                @(@{ 
                    Database="db1"
                    Owner = "correctlogin1" 
                }, @{ 
                    Database="db2"
                    Owner = "wronglogin" 
                }) |  
                Assert-DatabaseOwnerIsValid -With $testSettings
            } | Should -Throw
        }
    }

    Context "Validate database owner is not invalid check" {
        Mock Get-DbcConfigValue { return "invalidlogin1","invalidlogin2" } -ParameterFilter { $Name -like "policy.invaliddbowner.name" }
        Mock Get-DbcConfigValue { return "myExcludedDb" } -ParameterFilter { $Name -like "policy.invaliddbowner.excludedb" }
        
        $testSettings = Get-SettingsForDatabaseOwnerIsNotInvalidCheck

        It "The test should pass when the current owner is not what is invalid" {
            @(@{ 
                Database="db1"
                Owner = "correctlogin" 
            }) | 
            Assert-DatabaseOwnerIsNotInvalid -With $testSettings
        }

        It "The test should fail when the current owner is the invalid one" {
            {
                @(@{ 
                    Database="db1"
                    Owner = "invalidlogin1" 
                }) | 
                Assert-DatabaseOwnerIsNotInvalid -With $testSettings 
            } | Should -Throw
        }
        
        It "The test should fail when the current owner is any of the invalid ones" {
            {
                @(@{ 
                    Database="db1"
                    Owner = "invalidlogin2" 
                }) | 
                Assert-DatabaseOwnerIsNotInvalid -With $testSettings 
            } | Should -Throw
        }

        It "The test should pass when the invalid user is on an excluded database" {
            @(@{ 
                Database="db1"
                Owner = "correctlogin" 
            },@{ 
                Database="myExcludedDb"
                Owner = "invalidlogin2" 
            }) | 
            Assert-DatabaseOwnerIsNotInvalid -With $testSettings 
        }
    }

    Context "Validate recovery model checks" {
        It "The test should pass when the current recovery model is as expected" {
            $mock = [PSCustomObject]@{ RecoveryModel = "FULL" }
            Assert-RecoveryModel $mock -ExpectedRecoveryModel "FULL"
            $mock = [PSCustomObject]@{ RecoveryModel = "SIMPLE" }
            Assert-RecoveryModel $mock -ExpectedRecoveryModel "simple" # the assert should be case insensitive
        }

        It "The test should fail when the current recovery model is not what is expected" {
            $mock = [PSCustomObject]@{ RecoveryModel = "FULL" }
            { Assert-RecoveryModel $mock -ExpectedRecoveryModel "SIMPLE" } | Should -Throw
        }
    }

    Context "Validate the suspect pages check" {
        It "The test should pass when there are no suspect pages" {
            @{
                SuspectPages = 0
            } |
            Assert-SuspectPageCount  
        }
        It "The test should fail when there is even one suspect page" {
            {
                @{
                    SuspectPages = 1
                } | 
                Assert-SuspectPageCount 
            } | Should -Throw
        }
        It "The test should fail when there are many suspect pages" {
            {
                @{
                    SuspectPages = 10
                } | 
                Assert-SuspectPageCount 
            } | Should -Throw
        }
    }
}