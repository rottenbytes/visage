window.addEvent('domready', function () {

});

function showHide(divId)
{
    if (document.getElementById(divId).style.display=="block")
    {
        document.getElementById(divId).style.display="none";
    }
    else
    {
        document.getElementById(divId).style.display="block";
    }
}

function jumpto(selected) {
	parent.location.href = "/"+selected
}

