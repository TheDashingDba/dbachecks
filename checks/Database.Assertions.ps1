<# It is important to test our test. It really is. 
 # (http://jakubjares.com/2017/12/07/testing-your-environment-tests/)
 #
 #   To be able to do it with Pester one has to keep the test definition and the assertion 
 # in separate files. Write a new test, or modifying an existing one typically involves 
 # modifications to the three related files:
 #
 # /checks/Database.Assertions.ps1 (this file)              - where the assertions are defined
 # /checks/Database.Tests.ps1                               - where the assertions are used to check stuff
 # /tests/checks/Database.Assetions.Tests.ps1               - where the assertions are unit tests
 #>
 
. $PSScriptRoot/../internal/functions/Convert-ConfigValueToBoolean.ps1 

function Get-SettingsForAutoCloseCheck {
    return @{
        AutoClose = (Get-DbcConfigValue policy.database.autoclose | Convert-ConfigValueToBoolean)
    }
} 

function Assert-AutoClose {
    param (
        [parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [object[]]$TestObject,
        [parameter(Mandatory=$true)][Alias("With")]
        [object]$TestSettings,
        [string]$Because
    )
    process {
        $TestObject.AutoClose | Should -Be $TestSettings.AutoClose -Because $Because
    }
}

function Get-SettingsForDatabaseCollactionCheck {
    $Wrongcollation = Get-DbcConfigValue policy.database.wrongcollation
    return @{
        WrongCollation = $Wrongcollation
        ExcludedDatabase = @("ReportingServer", "ReportingServerTempDB")+@($Wrongcollation)
    }
}

function Assert-DatabaseCollation {
    param (
        [parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [object[]]$TestObject,
        [parameter(Mandatory=$true)][Alias("With")]
        [object]$TestSettings,
        [string]$Because
    )
    process {
        if ($TestObject.Database -in $TestSettings.ExcludedDatabase) {
            # if it is one of the excluded databases than we expect the database collation not to match the server one
            $TestObject.DatabaseCollation | Should -Not -Be $TestObject.ServerCollation -Because $Because 
        } else { 
            # otherwise it should match
            $TestObject.DatabaseCollation | Should -Be $TestObject.ServerCollation -Because $Because 
        }
    }
}

function Get-SettingsForDatabaseOwnerIsValidCheck {
    return @{
        ExpectedOwner = @(Get-DbcConfigValue policy.validdbowner.name)
        ExcludedDatabase = @(Get-DbcConfigValue policy.validdbowner.excludedb)
    }
}

function Assert-DatabaseOwnerIsValid {
    param (
        [parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [object[]]$TestObject, 
        [parameter(Mandatory=$true)][Alias("With")]
        [object]$TestSettings,
        [string]$Because
    )
    process {
        if (!($TestObject.Database -in $TestSettings.ExcludedDatabase)) {
            $TestObject.Owner | Should -BeIn $TestSettings.ExpectedOwner -Because $Because
        }
    }
}

function Get-SettingsForDatabaseOwnerIsNotInvalidCheck {
    return @{
        InvalidOwner = @(Get-DbcConfigValue policy.invaliddbowner.name)
        ExcludedDatabase = @(Get-DbcConfigValue policy.invaliddbowner.excludedb)
    }
}

function Assert-DatabaseOwnerIsNotInvalid {
    param (
        [parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [object[]]$TestObject, 
        [parameter(Mandatory=$true)][Alias("With")]
        [object]$TestSettings,
        [string]$Because
    )
    process {
        if (!($TestObject.Database -in $TestSettings.ExcludedDatabase)) {
            $TestObject.Owner | Should -Not -BeIn $TestSettings.InvalidOwner -Because $Because
        }
    }
}

function Get-SettingsForPageVerifyCheck {
    $pageverifyValidValues = @("NONE", "TORN_PAGE_DETECTION", "CHECKSUM")
    $pageverify = Get-DbcConfigValue policy.pageverify
    if (!($pageverify -in $pageverifyValidValues)) {
        throw "The policy.pageverify is set to $pageverify. Valid values are ($($pageverifyValidValues.Join(", ")))"
    }
    return @{
        PageVerify = (Get-DbcConfigValue policy.pageverify)
    }
}

function Assert-PageVerify {
    param (
        [parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [object[]]$TestObject, 
        [parameter(Mandatory=$true)][Alias("With")]
        [object]$TestSettings,
        [string]$Because
    )
    process {
        $TestObject.PageVerify | Should -Be $TestSettings.PageVerify -Because $Because
    }
}

function Assert-RecoveryModel {
    param (
        [object]$TestObject,
        [string]$ExpectedRecoveryModel,
        [string]$Because
    )
    $TestObject.RecoveryModel | Should -Be $ExpectedRecoveryModel -Because $Because
}

function Assert-SuspectPageCount {
    param (
        [parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [object[]]$TestObject,
        [string]$Because
    )
    process {
        $TestObject.SuspectPages | Should -Be 0 -Because $Because
    }
}