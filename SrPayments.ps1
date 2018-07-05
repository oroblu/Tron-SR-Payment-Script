###################################################################################################
# 
# POWERSHELL 4.0 OR HIGHER IS REQUIRED !!!
#
# This script generates 3 files
# SRvotes.csv ->  excel file with summuary of votes and rewards
# SRvotes.html ->  web page with summary of votes and reward  , can be published in a web server
# Pay.sp1 -> powershell script to run payments
#
###################################### Parameters #################################################
$payURL="https://api.tronscan.org/api/transaction-builder/contract/transfer"# URL used to create transaction for voters payments
$SRaddress="TGj1Ej1qRzL9feLTLhjwgxXF4Ct6GTWg2U"								# super representative address
$pkey="1111111111111111111111111111111111111111111111111111111111111111"								# super representative private key
$minPayOut=1								# if payout is less then this value (in TRX) no TRX will be paied
$minVoteMinutes=1							# minimum duration time for a vote, to get voter rewarded
$rewardPercentage=100							# perecentage dedicated of the total reward (Allowance)

##################################### Get data via APIs ###########################################

cd  $(Split-Path $script:MyInvocation.MyCommand.Path)


$JsonAllowance = Invoke-WebRequest "https://api.tronscan.org/api/account/$SRaddress"
$SRreward= ($JsonAllowance | ConvertFrom-Json | select -expand representative).allowance
$SRreward = $SRreward * $rewardPercentage / 100

##################################### Retrive multiple pages from  json API ########################
$i=0
$JsonContent=$null
do
{
    echo "... retrive https://api.tronscan.org/api/vote?limit=100&start=$($i)00&sort=timestamp&candidate=$SRaddress"
$JsonData = Invoke-WebRequest "https://api.tronscan.org/api/vote?limit=100&start=$($i)00&sort=timestamp&candidate=$SRaddress" -TimeoutSec 10

$JsonSplitted=($JsonData.Content).Split([char]0x005b,[char]0x005d)
$JsonContent=$JsonContent + "," + $JsonSplitted[1]
Start-Sleep -s 2
$i++
}
while ( $JsonSplitted[1] -ne "")
$JsonContentTrimmed= $JsonContent.Substring(1)
$JsonVotes = $JsonSplitted[0] + "[" + $JsonContentTrimmed.substring(0,$JsonContentTrimmed.length - 1) + "]" + $JsonSplitted[2]
###################################################################################################


$myVoters=($JsonVotes | ConvertFrom-Json).total
$myTotalVotes=($JsonVotes | ConvertFrom-Json).totalvotes


$myTab = $JsonVotes | ConvertFrom-Json   | select -expand data content |

Select-Object   @{Label = "Voter Address";Expression ={($_.VoterAddress)}},
    @{Label = "Votes";Expression ={($_.Votes)}}, 
    @{Label = "Vote Date UTC";Expression ={(($_.timestamp).replace('T'," ")).replace('Z','') }},
    @{Label = "Time from Vote in Minutes";Expression ={ [math]::Round((NEW-TIMESPAN –end  ([System.DateTime]::UtcNow).ToString("yyyy-MM-dd HH:mm:ss") -start (($_.timestamp).replace('T'," ")).replace('Z','')).TotalMinutes) }},
    @{Label = "Percentage % over total Votes";Expression ={ $_.votes/$myTotalVotes*100}},
    @{Label = "Reward (TRX)";Expression ={ [math]::Round($_.votes/$myTotalVotes*100*$SRreward/100/1000000,6)}},
    @{Label = "Real Reward (TRX)";Expression ={ $rew = $_.votes/$myTotalVotes*$SRreward/1000000 ; 
                                                if ( $rew -ge $minPayOut -and (NEW-TIMESPAN –end  ([System.DateTime]::UtcNow).ToString("yyyy-MM-dd HH:mm:ss") -start (($_.timestamp).replace('T'," ")).replace('Z','')).totalminutes -gt $minVoteminutes ) 
                                                    { [math]::Round($rew)} 
                                                else 
                                                    {0} 
                                               } 
     }
    
  

################################# Create  Excel  file summuary SRvotes.csv ############################


$myTab | Export-Csv -Delimiter "`t" -Encoding Unicode -Path SRvotes.csv -NoTypeInformation


################################ Create  HTML  file summary SRvotes.html ##############################

#This is the CSS used to add the style to the report

$Css="<style>
body {
    font-family: Verdana, sans-serif;
    font-size: 14px;
	color: #666666;
	background: #FEFEFE;
}
#title{
	color:#90B800;
	font-size: 30px;
	font-weight: bold;
	padding-top:25px;
	margin-left:35px;
	height: 50px;
}
#subtitle{
	font-size: 11px;
	margin-left:35px;
}
#main {
	position:relative;
	padding-top:10px;
	padding-left:10px;
	padding-bottom:10px;
	padding-right:10px;
}
#box1{
	position:absolute;
	background: #F8F8F8;
	border: 1px solid #DCDCDC;
	margin-left:10px;
	padding-top:10px;
	padding-left:10px;
	padding-bottom:10px;
	padding-right:10px;
}
#boxheader{
	font-family: Arial, sans-serif;
	padding: 5px 20px;
	position: relative;
	z-index: 20;
	display: block;
	height: 30px;
	color: #777;
	text-shadow: 1px 1px 1px rgba(255,255,255,0.8);
	line-height: 33px;
	font-size: 19px;
	background: #fff;
	background: -moz-linear-gradient(top, #ffffff 1%, #eaeaea 100%);
	background: -webkit-gradient(linear, left top, left bottom, color-stop(1%,#ffffff), color-stop(100%,#eaeaea));
	background: -webkit-linear-gradient(top, #ffffff 1%,#eaeaea 100%);
	background: -o-linear-gradient(top, #ffffff 1%,#eaeaea 100%);
	background: -ms-linear-gradient(top, #ffffff 1%,#eaeaea 100%);
	background: linear-gradient(top, #ffffff 1%,#eaeaea 100%);
	filter: progid:DXImageTransform.Microsoft.gradient( startColorstr='#ffffff', endColorstr='#eaeaea',GradientType=0 );
	box-shadow: 
		0px 0px 0px 1px rgba(155,155,155,0.3), 
		1px 0px 0px 0px rgba(255,255,255,0.9) inset, 
		0px 2px 2px rgba(0,0,0,0.1);
}
table{
	width:100%;
	border-collapse:collapse;
}
table td, table th {
	border:1px solid #98bf21;
	padding:3px 7px 2px 7px;
}
table th {
	text-align:left;
	padding-top:5px;
	padding-bottom:4px;
	background-color:#90B800;
color:#fff;
}
table tr.alt td {
	color:#000;
	background-color:#EAF2D3;
}
</style>"

$Body="<h3>Minimum payout is set to $minPayOut TRX </h3>
<h3>Minimum time elapsed from vote to get rewarded is set to $minVoteMinutes minutes ( $($minVoteMinutes/60) hours ) </h3>
<h3>Total reward amount from your Super Representative:  $($SRreward/1000000) TRX </h3>
<h3>Total amount of voters:  $myVoters </h3>"



$myTab | ConvertTo-Html -Head $Css -Body $body  | out-file -FilePath SRVotes.html



################################### Create payment script SRvotes.csv #####################################################
$csvPayment= Import-Csv -Delimiter "`t" -Encoding Unicode -Path SRvotes.csv

'######################################################################################'  > SRpay.ps1
'# This script run the transaction for voters payments'                                  >> SRpay.ps1
'# An Excel file "PayResult.csv" will be generated, with results for each transaction'   >> SRpay.ps1
'######################################################################################' >> SRpay.ps1
'cd  $(Split-Path $script:MyInvocation.MyCommand.Path)'                                  >> SRpay.ps1
'$myBalance=(Invoke-WebRequest "https://api.tronscan.org/api/account/' + $SRaddress + '"| ConvertFrom-Json ).balance' >> SRpay.ps1
'if ( ' + $SRreward + ' + 10000000 -gt   $myBalance ) { "Total rewards + 10 TRX is $(10 + ' + $SRreward + '/1000000) but your balance is only $($mybalance/100000)" > PayResult.csv ; exit }' >> SRpay.ps1
'"Voter Address `t Transaction `t Succes `t message"  > PayResult.csv'                   >> SRpay.ps1

foreach( $payment in $csvPayment)
    {
       if ("VoterAddress",$payment.'voter address'-eq $SRaddress -or $payment.'Real Reward (TRX)' -eq 0 ) 
        {
            #out-file Srpay.ps1 -Append -InputObject "#  $($payment.'voter address')  has  not reached reward requirements"     
        }
       else
        {
            $jsBody='{
                    "contract": {
                                "ownerAddress": "SRAddress",
                                "toAddress": "VoterAddress",
                                "amount": reward
                                },
                    "key": "pkey",
                    "broadcast": true
                     }'

            $jsBody=$jsBody.Replace("SRAddress",$SRaddress)
            $jsBody=$jsBody.Replace("VoterAddress",$payment.'voter address')
            $jsBody=$jsBody.Replace("reward",$(1000000*$payment.'Real Reward (TRX)'))
            $jsBody=$jsBody.Replace("pkey",$pkey)
            $jsBody= "'" + $jsBody + "'"
           
            out-file Srpay.ps1 -Append -InputObject '####################################################################' 
            out-file Srpay.ps1 -Append -InputObject '#'
            out-file Srpay.ps1 -Append -InputObject "#  Pay $($payment.'voter address')"                                                                                                                                                                        
            out-file Srpay.ps1 -Append -InputObject '#'
            out-file Srpay.ps1 -Append -InputObject '####################################################################' 
            out-file Srpay.ps1 -Append -InputObject "`$jsBody=  $jsBody" 
            out-file Srpay.ps1 -Append -InputObject "Start-Sleep -s 1"   
            out-file Srpay.ps1 -Append -InputObject "echo  `"......paying $($payment.'voter address') `""                                                                                                                                                                                                                                                                                                                                                         
            out-file Srpay.ps1 -Append -InputObject ('$payResult=Invoke-RestMethod -Method POST -uri "' + $payURL + '" -Body $jsBody -ContentType "application/json" -Headers @{"accept"="application/json"}')
            out-file Srpay.ps1 -Append -InputObject 'echo "$($payResult.result.message)"'  
            out-file Srpay.ps1 -Append -InputObject ('"' + $payment.'voter address' + '`t $($payResult.transaction.hash) `t $($payResult.success)  `t $($payResult.result.message)" >> PayResult.csv')       
        }
    }

