using namespace System.Text
using namespace System.IO
using namespace System.Management.Automation

function Merge-Csv {
    [cmdletbinding()]
    param(
        [Parameter(Position = 0, Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [alias('FullName')]
        [string[]] $Path,

        [Parameter(Mandatory)]
        [string] $DestinationPath,

        [Parameter()]
        [EncodingTransformation()]
        [ArgumentCompleter([EncodingCompleter])]
        [Encoding] $Encoding = 'utf8',

        [Parameter()]
        [switch] $PassThru,

        [Parameter()]
        [switch] $Force
    )

    begin {
        $isFirstObject = $true
        $Destination   = $PSCmdlet.GetUnresolvedProviderPathFromPSPath($DestinationPath)
    }

    process {
        foreach($chunk in $Path) {
            try {
                $reader  = [StreamReader]::new($chunk, $Encoding, $true)
                $headers = $reader.ReadLine()

                if($isFirstObject) {
                    $params = @{
                        Path        = $Destination
                        ItemType    = 'File'
                        Force       = $Force.IsPresent
                        ErrorAction = 'Stop'
                    }
                    $Destination   = New-Item @params
                    $isFirstObject = $false
                    $writer        = [StreamWriter]::new($Destination, $Encoding)
                    $writer.WriteLine($headers)
                }

                while(-not $reader.EndOfStream) {
                    $writer.WriteLine($reader.ReadLine())
                }
            }
            catch [DirectoryNotFoundException] {
                $PSCmdlet.ThrowTerminatingError(
                    [ErrorRecord]::new(
                        [DirectoryNotFoundException]::new(
                            $_.Exception.Message +
                            ' Use the -Force parameter to create new folders.'
                        ),
                        'DirectoryNotFound',
                        [ErrorCategory]::WriteError,
                        $DestinationPath
                    )
                )
            }
            catch [IOException] {
                if($_.Exception.Message.EndsWith('already exists.')) {
                    $PSCmdlet.ThrowTerminatingError(
                        [ErrorRecord]::new(
                            [IOException]::new(
                                $_.Exception.Message +
                                ' Use the -Force parameter to overwrite the file.'
                            ),
                            'FileExists',
                            [ErrorCategory]::WriteError,
                            $DestinationPath
                        )
                    )
                }
                $PSCmdlet.ThrowTerminatingError($_)
            }
            catch {
                $PSCmdlet.ThrowTerminatingError($_)
            }
            finally {
                if($reader) {
                    $reader.Dispose()
                }
            }
        }
    }
    end {
        if($writer) {
            $writer.Dispose()
        }

        if($PassThru.IsPresent) {
            $Destination
        }
    }
}