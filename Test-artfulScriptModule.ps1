function Test-artfulScriptModule {

<#
.SYNOPSIS
    Tests that all functions in a module are being exported.
 
.DESCRIPTION
    Test-MrFunctionsToExport is an advanced function that runs a Pester test against
    one or more modules to validate that all functions are being properly exported.
 
.PARAMETER ManifestPath
    Path to the module manifest (PSD1) file for the modules(s) to test.
.EXAMPLE
    Test-MrFunctionsToExport -ManifestPath .\MyModuleManifest.psd1
.EXAMPLE
    Get-ChildItem -Path .\Modules -Include *.psd1 -Recurse | Test-MrFunctionsToExport
.INPUTS
    String
 
.OUTPUTS
    None
 
.NOTES
    Author:  Mike F Robbins
    Website: http://mikefrobbins.com
    Twitter: @mikefrobbins
#>

    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline)]
        [ValidateScript({
            Test-ModuleManifest -Path $_
        })]
        [string[]]$ManifestPath
    )
    
    PROCESS {
        foreach ($Manifest in $ManifestPath) {

            $ModuleInfo = Import-Module -Name $Manifest -Force -PassThru

            $PS1FileNames = Get-ChildItem -Path "$($ModuleInfo.ModuleBase)\*.ps1" -Exclude *tests.ps1, *profile.ps1 |
                            Select-Object -ExpandProperty BaseName

            $ExportedFunctions = Get-Command -Module $ModuleInfo.Name |
                                 Select-Object -ExpandProperty Name
                                 
            $manifestfile = Get-Item $manifest
            
            $allfileslist = Get-ChildItem -Path "$($ModuleInfo.ModuleBase)\*.*" -Exclude "$($ModuleInfo.Name).psd1", "$($ModuleInfo.Name).psm1" | Select-Object -ExpandProperty Fullname
  
          
          Describe "FunctionsToExport for PowerShell module '$($ModuleInfo.Name)'" {
          
                It 'Contains a module in the correct folder name' {
                  $manifestfile.BaseName | Should Be $manifestfile.Directory.Name
                }
                
                It 'Contains a root module with the same name as the module' {
                  $ModuleInfo.RootModule | Should Be $manifestfile.BaseName
                }

                It 'Exports one function in the module manifest per PS1 file' {
                    $ModuleInfo.ExportedFunctions.Values.Name.Count |
                    Should Be $PS1FileNames.Count
                }

                It 'Exports functions with names that match the PS1 file base names' {
                    Compare-Object -ReferenceObject $ModuleInfo.ExportedFunctions.Values.Name -DifferenceObject $PS1FileNames |
                    Should BeNullOrEmpty
                }

                It 'Only exports functions listed in the module manifest' {
                    $ExportedFunctions.Count |
                    Should Be $ModuleInfo.ExportedFunctions.Values.Name.Count
                }

                It 'Contains the same function names as base file names' {
                    Compare-Object -ReferenceObject $PS1FileNames -DifferenceObject $ExportedFunctions |
                    Should BeNullOrEmpty
                }
                It 'Only contains files listed in the module manifest' {
                    Compare-Object -ReferenceObject $ModuleInfo.filelist -DifferenceObject $allfileslist | Should BeNullOrEmpty
                }
            }
          
          Foreach ($function in $ExportedFunctions) {
            Describe "Function Help for '$($function)'" {
              $help = Get-Help $function
              It "The Function $function should have a custom help Synopsis" {
                $help.Synopsis | should not contain "$function"
                $help.Synopsis | Should not BeNullOrEmpty
                $help.Synopsis | Should not BeLike "Describe purpose of *"
              }
              It "The function $function should have a custom help description" {
                $help.description | Should not BeNullOrEmpty
                $help.description | Should not BeLike "Add a more complete description of what the function does.*"
              }
              It "The function $function should have a custom Link and not be empty" {
                $help.relatedLinks | Should not BeNullOrEmpty
                $help.relatedLinks | Should not belike "URLs to related sites*" 
              }
              Foreach ($example in $help.examples.example) {
                It "The function $function should have custom examples" {
                  $example.remarks.text | Should not BeNullOrEmpty
                  $example.remarks.text | Should not Contain "Describe what this call does"
                }
              }
            } 
            
          }
          
          
    
        }

    }

}