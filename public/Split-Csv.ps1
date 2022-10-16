using namespace System.Text
using namespace System.IO

function Split-Csv {
    [CmdletBinding(DefaultParameterSetName = 'ByChunks')]
    param(
        [Parameter(Position = 0, Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [alias('FullName')]
        [string] $Path,

        [Parameter(Mandatory)]
        [string] $DestinationFolder,

        [Parameter(ParameterSetName = 'BySize')]
        [int64] $Size = 1kb,

        [Parameter(ParameterSetName = 'ByChunks')]
        [int32] $Chunks = 3,

        [Parameter()]
        [EncodingTransformation()]
        [ArgumentCompleter([EncodingCompleter])]
        [Encoding] $Encoding = 'utf8',

        [Parameter()]
        [switch] $PassThru
    )

    begin {
        $Destination = $PSCmdlet.GetUnresolvedProviderPathFromPSPath($DestinationFolder)

        class ChunkWriter {
            [FileInfo] $Source
            [string] $Destination
            [string] $Headers
            [string] $Format
            [Encoding] $Encoding

            [StreamWriter] GetNewWriter([int32] $Index) {
                $name     = [string]::Format(
                    '{0} - Part {1}{2}',
                    $this.Source.BaseName,
                    $Index.ToString($this.Format),
                    $this.Source.Extension
                )
                $newChunk = Join-Path $this.Destination -ChildPath $name
                $writer   = [StreamWriter]::new($newChunk, $false, $this.Encoding)
                $writer.AutoFlush = $true
                $writer.WriteLine($this.Headers)
                return $writer
            }
        }
    }
    process {
        try {
            [FileInfo] $Path = $PSCmdlet.GetUnresolvedProviderPathFromPSPath($Path)
            $null    = [Directory]::CreateDirectory($Destination)
            $reader  = [StreamReader]::new($Path.FullName, $Encoding, $true)
            $headers = $reader.ReadLine()
            $Index   = 0

            if($PSCmdlet.ParameterSetName -eq 'ByChunks') {
                $chunkSize = ($Path.Length - $headers.Length) / $Chunks + ($headers.Length * $Chunks)
                $format    = 'D{0}' -f $Chunks.ToString().Length
            }
            else {
                $chunkSize = $Size - $headers.Length
                $format    = 'D{0}' -f [math]::Ceiling($Path.Length / $Size).ToString().Length
            }

            $chunkWriter = [ChunkWriter]@{
                Source      = $Path
                Destination = $Destination
                Headers     = $headers
                Format      = $format
                Encoding    = $Encoding
            }

            $writer = $chunkWriter.GetNewWriter($Index++)

            while(-not $reader.EndOfStream) {
                if($writer.BaseStream.Length -ge $chunkSize) {
                    $writer.Dispose()

                    if($PassThru.IsPresent) {
                        $writer.BaseStream.Name -as [FileInfo]
                    }

                    $writer = $chunkWriter.GetNewWriter($Index++)
                }
                $writer.WriteLine($reader.ReadLine())
            }
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }
        finally {
            $writer, $reader | ForEach-Object Dispose

            if($PassThru.IsPresent) {
                $writer.BaseStream.Name -as [FileInfo]
            }
        }
    }
}