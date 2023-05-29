<?php


if(!function_exists('callURL'))
{
    function callURL( $callURL, $callHeaders = null ){
        
        $ch = curl_init( $callURL );
        
        $options = array(
                         CURLOPT_HEADER => false,
                         CURLOPT_POST => count( $callHeaders ),
                         CURLOPT_POSTFIELDS => $callHeaders,
                         CURLOPT_RETURNTRANSFER => true,
						 CURLOPT_COOKIE => session_name(). '=' . session_id()
                        );
        
        curl_setopt_array($ch, $options);
        
        $rawResult = curl_exec( $ch );
        
        return $rawResult;
        
    }
}
if(!function_exists('curl_setopt_array'))
{
    function curl_setopt_array(&$ch, $curl_options){
        
        foreach ($curl_options as $option => $value) {
            if (!curl_setopt($ch, $option, $value)) {
                return false;
            } 
        }
        return true;
    }
}

$exVIEW = explode("/",$_REQUEST['view']);

if( strtolower($exVIEW[0]) == 'PanelDrive' && $exVIEW[1] != 'assets' ) header('location:'.str_replace($exVIEW[0].'/','',$_REQUEST['view']));


session_start();

if(isset($_REQUEST['username']))$_SESSION['username'] = $_REQUEST['username'];
if(isset($_REQUEST['password']))$_SESSION['password'] = $_REQUEST['password'];
if($exVIEW[0]=='logout' || $exVIEW[1]=='logout') unset($_SESSION['login']);

if(substr($_REQUEST['requested'],-4,4)==".css") header('Content-Type:text/css');
if(substr($_REQUEST['requested'],-3,3)==".js") header('Content-Type:text/javascript');
if(substr($_REQUEST['requested'],-4,4)==".png") header('Content-Type:image/png');
if(substr($_REQUEST['requested'],-4,4)==".jpg") header('Content-Type:image/jpeg');
if(substr($_REQUEST['requested'],-4,4)==".jpeg") header('Content-Type:image/jpeg');
if(substr($_REQUEST['requested'],-4,4)==".gif") header('Content-Type:image/gif');



$_REQUEST['panelID'] = 1653;
$_REQUEST['WL'] = true;
$_REQUEST['WL_CLIENT'] = $_SERVER['HTTP_HOST'];


if(isset($_REQUEST['login-email']) && isset($_REQUEST['login-password']))
{
    $_SESSION['login'] = array();
    $_SESSION['login']['email'] = $_REQUEST['login-email'];
    $_SESSION['login']['password'] = $_REQUEST['login-password'];
}

if(is_array($_SESSION['login']))
{
    $_REQUEST['PassEmail'] = $_SESSION['login']['email'];
    $_REQUEST['PassPassword'] = $_SESSION['login']['password'];
    
}


$REQ = $_REQUEST;

$JE = array();
foreach($REQ as $key=>$val)
{
    if(is_array($val)){ $REQ[$key] = json_encode($val); $JE[$key]=true; }
}
$REQ['JE'] = json_encode($JE);


$REQ['METHOD'] = $_SERVER['REQUEST_METHOD'];

if($exVIEW[0]=='assets') $panelReturn = callURL("http://startwhatever.com/".$_REQUEST['view']);
else $panelReturn = callURL("http://startwhatever.com/".$_REQUEST['view'],$REQ);

if(substr($_REQUEST['view'],-4,4)=='.jpg') header('Content-type:image/jpeg'); 
if(substr($_REQUEST['view'],-5,5)=='.jpeg') header('Content-type:image/jpeg');
if(substr($_REQUEST['view'],-4,4)=='.png') header('Content-type:image/png');
if(substr($_REQUEST['view'],-4,4)=='.gif') header('Content-type:image/gif');
if(substr($_REQUEST['view'],-4,4)=='.css') header('Content-type:text/css');
if(substr($_REQUEST['view'],-3,3)=='.js') header('Content-type:text/javscript');

echo $panelReturn;
?>
