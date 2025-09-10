// Initialize connection w Reaper
wwr_start();

// ~~~~~~~~~~~~~~~~~~~~
// GLOBAL VAR DECLARATION
// ~~~~~~~~~~~~~~~~~~~~
// Reaper-side Lua Script
var UCSRTLua = "_RS0d2de1418a084e66229cb513cdb6e8cc99fc7593"; //ACendan Scripts/Various/UCS Renaming Tool.lua
var UCSMediaFilter = "_RS15f4b156ba3f21ef8806a3c4c1f04ff621d48c9a"; //ACendan Scripts/Various/acendan_UCS Renaming Tool - Media Explorer Filter.lua
var UCSSendToInterface = "_RS6500fc52057a6aeabf8f4ecabc5c2d3f91cc6062"; //ACendan Scripts/Various/acendan_UCS Renaming Tool - Send To Interface.lua
var REApath = "40027"; // Open REAPER resource path

// UCS Google Sheet Languages
var ucs_gsheet_header = "https://spreadsheets.google.com/feeds/cells/10-IAYKOEpTMoDsv7m_oPZazPVY3HhhUS_hQeEjmK93c/";
var ucs_gsheet_footer = "/public/full?alt=json";
var ucs_gsheet_en = ucs_gsheet_header + "1" + ucs_gsheet_footer;
var ucs_gsheet_fr = ucs_gsheet_header + "2" + ucs_gsheet_footer;
var ucs_gsheet_pl = ucs_gsheet_header + "3" + ucs_gsheet_footer;
var ucs_gsheet_de = ucs_gsheet_header + "4" + ucs_gsheet_footer;
var ucs_gsheet_pt = ucs_gsheet_header + "5" + ucs_gsheet_footer;
var ucs_gsheet_pt_br = ucs_gsheet_header + "6" + ucs_gsheet_footer;
var ucs_gsheet_zh = ucs_gsheet_header + "7" + ucs_gsheet_footer;
var ucs_gsheet_nl = ucs_gsheet_header + "8" + ucs_gsheet_footer;
var ucs_gsheet_es = ucs_gsheet_header + "9" + ucs_gsheet_footer;
var ucs_gsheet_ja = ucs_gsheet_header + "10" + ucs_gsheet_footer;
var ucs_gsheet_it = ucs_gsheet_header + "11" + ucs_gsheet_footer;
var ucs_gsheet_da = ucs_gsheet_header + "12" + ucs_gsheet_footer;
var ucs_gsheet_fi = ucs_gsheet_header + "13" + ucs_gsheet_footer;
var ucs_gsheet_tw = ucs_gsheet_header + "14" + ucs_gsheet_footer;
var ucs_gsheet_no = ucs_gsheet_header + "15" + ucs_gsheet_footer;
var ucs_gsheet_se = ucs_gsheet_header + "16" + ucs_gsheet_footer;
var ucs_gsheet_ru = ucs_gsheet_header + "17" + ucs_gsheet_footer;
var ucs_gsheet_ua = ucs_gsheet_header + "18" + ucs_gsheet_footer;
var ucs_gsheet_tr = ucs_gsheet_header + "19" + ucs_gsheet_footer;
var ucs_gsheet_kr = ucs_gsheet_header + "20" + ucs_gsheet_footer;

// Arrays populated by Google Sheet public JSON
// Cleaned up arrays for auto-filter
var jsonFullTable = [];
var jsonCategoryAutofill = [];
var jsonSubcategoryAutofill = [];
var jsonCategorySubcategoryArr = [];
var jsonCatIDArr = [];

// Init user preset array
let userPresets = [];

// Instructions toggle bool
var onlineModeInstructionsToggle = true;

// Reacall handler
var reacallHandled = false;

// Platform specific bools
var isSafari = /constructor/i.test(window.HTMLElement) || (function (p) { return p.toString() === "[object SafariRemoteNotification]"; })(!window['safari'] || (typeof safari !== 'undefined' && safari.pushNotification));
var isMac = navigator.platform.toUpperCase().indexOf('MAC') >= 0;

// Cache load start time
var startTime = new Date().valueOf();

// Cache date getter
var month = new Date().getMonth() + 1;
var day = new Date().getDate();

// ~~~~~~~~~~~~~~~~~~~~
// ON PAGE LOAD
// Determine Online or Offline Mode
// ~~~~~~~~~~~~~~~~~~~~
$(function () {
    // Alert Safari users of issues with browser            
    if (isSafari) alert("Safari does not play nicely with this tool. I am working to resolve these issues, but until then, please consider using Google Chrome. Thank you for your understanding!");

    // Remove selected regions in region manager option for mac users
    // https://forum.cockos.com/showpost.php?p=2337785&postcount=1326
    // if (isMac) $("#userInputArea option:contains('Selected Regions in Region Manager')").remove();

    // Get previous session settings from local storage
    recallSettings();

    // Assigns country icon for current language to navbar language dropdown
    getUCSLanguage();

    // Attempt to load offline "UCS.txt" file if available. If successful: useOfflineUSCData()
    // If not, get data from public Google sheet via function: useGSheetsUSCData()
    loadOfflineUCSDoc();

    // Check for User Presets
    loadUserPresets();

    // Check for User History
    loadUserHistory();
});

// ~~~~~~~~~~~~~~~~~~~~
// CATCH ERROR IN LOADING COUNTRY STATE CITY API
// ~~~~~~~~~~~~~~~~~~~~
$.ajax({
    type: "POST",
    url: "http://geodata.solutions/api/api.php",
    success: function (msg) {
        // Success
    },
    error: function (XMLHttpRequest, textStatus, errorThrown) {
        console.log("Error: Failed to load CountryStateCity API!");

        // Force manual input
        $("#locationInputSettings").prop('checked', true);
        $("#locInputHeader").hide();
        $("#locInputDiv").hide();
        $("#metaLocDiv").hide();
        $("#metaUserLocDiv").show();
    }
});

// ~~~~~~~~~~~~~~~~~~~~
// RECALL STORAGE SETTINGS
// ~~~~~~~~~~~~~~~~~~~~
function recallSettings() {
    // Set dark mode if previously set or sys pref
    if (localStorage.getItem("color-mode") === "dark" || (window.matchMedia("(prefers-color-scheme: dark)").matches && !localStorage.getItem("color-mode"))) enableDarkMode();

    // Get copy results setting
    if (localStorage.getItem("copy-setting")) {
        $("#copyResultsSetting").val(localStorage.getItem("copy-setting"));
        if (localStorage.getItem("copy-setting") == "Copy WITHOUT processing") {
            $("#copyResultsWarning").show();
            $("#copyResultsWarning2").show();
        } else {
            $("#copyResultsWarning").hide();
            $("#copyResultsWarning2").hide();
        }
    } else {
        $("#copyResultsWarning").hide();
        $("#copyResultsWarning2").hide();
    }

    // Get render metadata setting
    if (localStorage.getItem("ixml-setting")) {
        $("#iXMLSettings").prop('checked', true);
        $("#metadataWarning").show();
    } else {
        $("#iXMLSettings").prop('checked', false);
    }

    // Get render directory setting
    if (localStorage.getItem("directory-setting")) {
        $("#renderDirectorySettings").prop('checked', true);
    } else {
        $("#renderDirectorySettings").prop('checked', false);
    }

    // Get location preference settings
    if (localStorage.getItem("location-input-setting")) {
        $("#locationInputSettings").prop('checked', true);
        $("#metaLocDiv").hide();
        $("#metaUserLocDiv").show();
    } else {
        $("#locationInputSettings").prop('checked', false);
        $("#metaLocDiv").show();
        $("#metaUserLocDiv").hide();
    }

    // Get marker position format setting
    if (localStorage.getItem("marker-pos-setting")) {
        $("#markerPositionSettings").prop('checked', true);
    } else {
        $("#markerPositionSettings").prop('checked', false);
    }

    // Get extended metadata setting
    if (localStorage.getItem("metadata-setting")) {
        $("#metadataSettings").prop('checked', true);
        $("#metadataWarning").show();
        $("#metadataTitle").show();
        $("#metadataSection").show();
        $("#metadataScroll").show();
    } else {
        $("#metadataSettings").prop('checked', false);
        $("#metadataTitle").hide();
        $("#metadataSection").hide();
        $("#metadataScroll").hide();
    }

    // Get ASWG metadata setting
    if (localStorage.getItem("aswg-setting")) {
        $("#ASWGSettings").prop('checked', true);
        $("#ASWGSection").show();
    } else {
        $("#ASWGSettings").prop('checked', false);
        $("#ASWGSection").hide();
    }

    // Get vendor cat setting
    if (localStorage.getItem("vendor-cat-setting")) {
        $("#vendorCatCheckbox").prop('checked', true);
        $("#vendorCategoryGroup").show();
    } else {
        $("#vendorCatCheckbox").prop('checked', false);
        $("#vendorCategoryGroup").hide();
    }

    // Hide metadata warning
    if (!localStorage.getItem("ixml-setting") && !localStorage.getItem("metadata-setting")) {
        $("#metadataWarning").hide();
    }

    // Get name/source capitalization settings
    if (localStorage.getItem("caps-setting")) {
        $("#nameCapitalizationSetting").val(localStorage.getItem("caps-setting"));
    }

    // Get filename formatting settings
    if (localStorage.getItem("fx-format-setting")) {
        $("#fxFormattingSetting").val(localStorage.getItem("fx-format-setting"));
    }

    // GBX Mod
    if (localStorage.getItem("gbx-mod")) {
        GBXMod();
    } else {
        $("#gbxSuffixGroup").hide();
    }
}

// ~~~~~~~~~~~~~~~~~~~~
// DROP-DOWN AUTOFILL
// ~~~~~~~~~~~~~~~~~~~~
var substringMatcher = function (strs) {
    return function findMatches(q, cb) {
        var matches, substringRegex;

        // an array that will be populated with substring matches
        matches = [];

        // regex used to determine if a string contains the substring `q`
        substrRegex = new RegExp(q, 'i');

        // iterate through the pool of strings and for any string that
        // contains the substring `q`, add it to the `matches` array
        $.each(strs, function (i, str) {
            if (substrRegex.test(str)) {
                matches.push(str);
            }
        });

        cb(matches);
    };
};

// ~~~~~~~~~~~~~~~~~~~~
// CATEGORY AUTOFILL INIT
// ~~~~~~~~~~~~~~~~~~~~
$('#typeaheadCategory .typeahead').typeahead({
    hint: true,
    highlight: true
},
    {
        name: 'jsonCategoryAutofill',
        source: substringMatcher(jsonCategoryAutofill)
    });

// ~~~~~~~~~~~~~~~~~~~~
//   LIGHT / DARK MODE
// ~~~~~~~~~~~~~~~~~~~~
const toggleColorMode = e => {
    /* ENABLE LIGHT MODE */
    if (e.currentTarget.classList.contains("light--hidden")) {
        enableLightMode();
        return;
    }

    /* ENABLE DARK MODE */
    enableDarkMode();
}

const toggleColorButtons = document.querySelectorAll(".color-mode__btn");
toggleColorButtons.forEach(btn => {
    btn.addEventListener("click", toggleColorMode);
});

function enableDarkMode() {
    document.documentElement.setAttribute("color-mode", "dark");
    localStorage.setItem("color-mode", "dark");

    $("#UCRTDataTable").removeClass("table-light");
    $("#UCRTDataTable").addClass("table-dark");

    $("#ucsNavbar").removeClass("navbar-light");
    $("#ucsNavbar").addClass("navbar-dark");

    $("#UCSInstallInstructions").removeClass("border-dark");
    $("#UCSInstallInstructions").addClass("border-light");

    $("#UCSOnlineModeInstructions").removeClass("border-dark");
    $("#UCSOnlineModeInstructions").addClass("border-light");
}

function enableLightMode() {
    document.documentElement.setAttribute("color-mode", "light");
    localStorage.setItem("color-mode", "light");

    $("#UCRTDataTable").removeClass("table-dark");
    $("#UCRTDataTable").addClass("table-light");

    $("#ucsNavbar").removeClass("navbar-dark");
    $("#ucsNavbar").addClass("navbar-light");

    $("#UCSInstallInstructions").removeClass("border-light");
    $("#UCSInstallInstructions").addClass("border-dark");

    $("#UCSOnlineModeInstructions").removeClass("border-light");
    $("#UCSOnlineModeInstructions").addClass("border-dark");
}

// ~~~~~~~~~~~~~~~~~~~~
// SUBMIT BUTTON & LUA TRIGGER
// ~~~~~~~~~~~~~~~~~~~~
// FORMAT: CatID_File Name with Variation Number_Initials_(Show)
// NEW FORMAT: CatID(-UserCategory)_(VendorCategory-)File Name with Variation Number_Initials_(Show)
$("#formSubmitButton").click(function (e) {
    // Check for wildcard/search type mismatch
    wildcardCleanup();

    // Process user input
    var selectedCategory = $("#userInputCategory").val();
    var selectedSubcategory = $("select#userSelectSubCategory option:checked").val();
    var selectedCatID = getCatID(selectedCategory, selectedSubcategory); // This function also alerts user if cat/subcat combo is invalid
    var nameAndNum = getNameAndNumber($("#userInputName").val());
    var nameOnly = nameAndNum[0];
    var numOnly = nameAndNum[1];
    var enableNum = $("#userInputVarNumCheckbox").prop("checked");
    var iXMLChecked = $("#iXMLSettings").prop("checked");
    var vendorChecked = $("#vendorCatCheckbox").prop("checked");
    var metadataChecked = $("#metadataSettings").prop("checked");
    var directoryChecked = $("#renderDirectorySettings").prop("checked");
    var locationChecked = $("#locationInputSettings").prop("checked");
    var markerPosChecked = $("#markerPositionSettings").prop("checked");
    var cleanUserCat = stringCleaning($("#userInputUserCat").val());
    var cleanInitials = stringCleaning($("#userInputInitials").val());
    var cleanShow = stringCleaning($("#userInputShow").val());
    var cleanUserData = stringCleaning($("#userInputData").val());
    var gbxMod = localStorage.getItem("gbx-mod");

    // Alert user of invalid entries and bypass triggering ReaScript
    if (selectedCatID == "CATID_INVALID") { return; }                           // Alert is included in getCatID above
    if (nameOnly == "") { $("#userInputNameError").show(); $("#userCategoryGroup")[0].scrollIntoView(); return; }
    if (cleanInitials == "" && !gbxMod) { $("#userInitialsError").show(); $("#fileNameGroup")[0].scrollIntoView(); return; }
    if ($("#ASWGcontentType").val() !== "-" && $("#ASWGInfoForm").hasClass("was-validated") && $("#ASWGInfoForm")[0].checkValidity() === false) { $("#ASWGInfoModal").modal(); $("#ASWGInfoFormError").show(); return; }
    if ($("#ASWGcontentType").val() !== "-" && $("#ASWGDialogueForm").hasClass("was-validated") && $("#ASWGDialogueForm")[0].checkValidity() === false) { $("#ASWGDialogueModal").modal(); $("#ASWGDialogueFormError").show(); return; }
    if ($("#ASWGcontentType").val() !== "-" && $("#ASWGMusicForm").hasClass("was-validated") && $("#ASWGMusicForm")[0].checkValidity() === false) { $("#ASWGMusicModal").modal(); $("#ASWGMusicFormError").show(); return; }

    // Trigger CSS Animation
    $("#formSubmitButton").addClass('anim-trig');
    $("#formSubmitButton").one('webkitAnimationEnd oanimationend msAnimationEnd animationend',
        function (e) {
            // Code to execute after animation ends
            $("#formSubmitButton").removeClass('anim-trig');
        });

    // Set project extstates from processed vars
    setProjExtState(selectedCategory, "Category");
    setProjExtState(selectedSubcategory, "Subcategory");
    setProjExtState(selectedCatID, "CatID");
    setProjExtState(nameOnly, "Name");
    setProjExtState(numOnly, "Number");
    setProjExtState(enableNum, "EnableNum");
    setProjExtState(iXMLChecked, "iXMLMetadata");
    setProjExtState(metadataChecked, "ExtendedMetadata");
    setProjExtState(directoryChecked, "RenderDirectory");
    setProjExtState(markerPosChecked, "MarkerPosition");
    setProjExtState(cleanUserCat, "UserCategory");
    setProjExtState(cleanInitials, "Initials");
    setProjExtState(cleanShow, "Show");
    setProjExtState(cleanUserData, "Data");

    // Set project extstates from HTML vals
    setProjExtState("userInputItems");
    setProjExtState("userInputArea");
    setProjExtState("nameCapitalizationSetting");
    setProjExtState("fxFormattingSetting");
    setProjExtState("copyResultsSetting");

    // Vendor category
    console.log("Vendor checked = " + vendorChecked);
    if (vendorChecked) {
        var vendorCat = stringCleaning($("#userInputVendCat").val());
        setProjExtState(vendorCat, "VendorCategory");
    } else {
        setProjExtState("false", "VendorCategory");
    }

    // Set project extstates for extended metadata fields             
    if (metadataChecked) {
        // Extended metadata fields
        var metaTitle = stringCleaning($("#userInputMetaTitle").val());
        var metaDesc = $("#userInputMetaDesc").val();
        var metaKeys = stringCleaning($("#userInputMetaKeys").val());
        var metaMic = stringCleaning($("#userInputMetaMic").val());
        var metaRecMed = stringCleaning($("#userInputMetaRecMed").val());
        var metaDsgnr = stringCleaning($("#userInputMetaDsgnr").val());
        var metaLib = stringCleaning($("#userInputMetaLib").val());
        var metaURL = $("#userInputMetaURL").val();
        var metaMftr = $("#userInputMetaManufacturer").val();
        var metaNotes = $("#metaNotes").val();

        // Extended metadata - location
        var metaCoun = $("#countryId").val();
        var metaState = $("#stateId").val();
        var metaCity = $("#cityId").val();
        var metaUserLoc = $("#userLocId").val();
        var metaLoc = "";
        if (locationChecked) {
            // Custom user field
            metaLoc = metaUserLoc;
        } else {
            // Country, city, state dropdowns
            if (metaCoun != "Please wait.." && metaCoun != "Select Country" && metaCoun != "") metaLoc = metaCoun;
            if (metaState != "Please wait.." && metaState != "Select State" && metaState != "") {
                (metaLoc != "") ? metaLoc = metaLoc + ", " + metaState : metaLoc = metaState;
            }
            if (metaCity != "Please wait.." && metaCity != "Select City" && metaCity != "") {
                (metaLoc != "") ? metaLoc = metaLoc + ", " + metaCity : metaLoc = metaCity;
            }
        }


        // Extended metadata - mic perspective
        var metaConfig = $("#userInputMetaConfig").val();
        metaConfig = (metaConfig != "-") ? metaConfig.match(/\((.*)\)/).pop() : "";

        var metaPersp = $("#userInputMetaPersp").val();
        var metaIntExt = $("#userInputMetaIntExt").val();
        if (metaPersp != "-" && metaIntExt != "-") {
            metaPersp = metaPersp.match(/\((.*)\)/).pop() + " | " + metaIntExt.match(/\((.*)\)/).pop();
        } else if (metaPersp != "-" && metaIntExt == "-") {
            metaPersp = metaPersp.match(/\((.*)\)/).pop();
        } else if (metaPersp == "-" && metaIntExt != "-") {
            metaPersp = metaIntExt.match(/\((.*)\)/).pop();
        } else if (metaPersp == "-" && metaIntExt == "-") {
            metaPersp = "";
        }

        setProjExtState(metaTitle, "MetaTitle");
        setProjExtState(metaDesc, "MetaDesc");
        setProjExtState(metaKeys, "MetaKeys");
        setProjExtState(metaMic, "MetaMic");
        setProjExtState(metaRecMed, "MetaRecMed");
        setProjExtState(metaDsgnr, "MetaDsgnr");
        setProjExtState(metaLib, "MetaLib")
        setProjExtState(metaLoc, "MetaLoc");
        setProjExtState(metaURL, "MetaURL");
        setProjExtState(metaMftr, "MetaMftr");
        setProjExtState(metaNotes, "MetaNotes");
        setProjExtState(metaConfig, "MetaConfig");
        setProjExtState(metaPersp, "MetaPersp");
    }

    //#region Fetch ASWG fields           
    var aswgChecked = $("#ASWGSettings").prop("checked");
    if (aswgChecked) {
        var ASWGcontentType = $("#ASWGcontentType").val();
        var ASWGproject = $("#ASWGproject").val();
        var ASWGoriginatorStudio = $("#ASWGoriginatorStudio").val();
        var ASWGnotes = $("#ASWGnotes").val();
        var ASWGstate = $("#ASWGstate").val();
        var ASWGeditor = $("#ASWGeditor").val();
        var ASWGmixer = $("#ASWGmixer").val();
        var ASWGfxChainName = $("#ASWGfxChainName").val();
        var ASWGchannelConfig = $("#ASWGchannelConfig").val();
        var ASWGambisonicFormat = $("#ASWGambisonicFormat").val();
        var ASWGambisonicChnOrder = $("#ASWGambisonicChnOrder").val();
        var ASWGambisonicNorm = $("#ASWGambisonicNorm").val();
        var ASWGisDesigned = $("#ASWGisDesigned").val();
        var ASWGrecEngineer = $("#ASWGrecEngineer").val();
        var ASWGrecStudio = $("#ASWGrecStudio").val();
        var ASWGimpulseLocation = $("#ASWGimpulseLocation").val();
        var ASWGtext = $("#ASWGtext").val();
        var ASWGefforts = $("#ASWGefforts").val();
        var ASWGeffortType = $("#ASWGeffortType").val();
        var ASWGprojection = $("#ASWGprojection").val();
        var ASWGlanguage = $("#ASWGlanguage").val();
        var ASWGtimingRestriction = $("#ASWGtimingRestriction").val();
        var ASWGcharacterName = $("#ASWGcharacterName").val();
        var ASWGcharacterGender = $("#ASWGcharacterGender").val();
        var ASWGcharacterAge = $("#ASWGcharacterAge").val();
        var ASWGcharacterRole = $("#ASWGcharacterRole").val();
        var ASWGactorName = $("#ASWGactorName").val();
        var ASWGactorGender = $("#ASWGactorGender").val();
        var ASWGdirection = $("#ASWGdirection").val();
        var ASWGdirector = $("#ASWGdirector").val();
        var ASWGfxUsed = $("#ASWGfxUsed").val();
        var ASWGusageRights = $("#ASWGusageRights").val();
        var ASWGisUnion = $("#ASWGisUnion").val();
        var ASWGaccent = $("#ASWGaccent").val();
        var ASWGemotion = $("#ASWGemotion").val();
        var ASWGcomposer = $("#ASWGcomposer").val();
        var ASWGartist = $("#ASWGartist").val();
        var ASWGsongTitle = $("#ASWGsongTitle").val();
        var ASWGgenre = $("#ASWGgenre").val();
        var ASWGsubGenre = $("#ASWGsubGenre").val();
        var ASWGproducer = $("#ASWGproducer").val();
        var ASWGmusicSup = $("#ASWGmusicSup").val();
        var ASWGinstrument = $("#ASWGinstrument").val();
        var ASWGmusicPublisher = $("#ASWGmusicPublisher").val();
        var ASWGrightsOwner = $("#ASWGrightsOwner").val();
        var ASWGintensity = $("#ASWGintensity").val();
        var ASWGorderRef = $("#ASWGorderRef").val();
        var ASWGisSource = $("#ASWGisSource").val();
        var ASWGisLoop = $("#ASWGisLoop").val();
        var ASWGisFinal = $("#ASWGisFinal").val();
        var ASWGisOst = $("#ASWGisOst").val();
        var ASWGisCinematic = $("#ASWGisCinematic").val();
        var ASWGisLicensed = $("#ASWGisLicensed").val();
        var ASWGisDiegetic = $("#ASWGisDiegetic").val();
        var ASWGmusicVersion = $("#ASWGmusicVersion").val();
        var ASWGisrcId = $("#ASWGisrcId").val();
        var ASWGtempo = $("#ASWGtempo").val();
        var ASWGtimeSig = $("#ASWGtimeSig").val();
        var ASWGinKey = $("#ASWGinKey").val();
        var ASWGbillingCode = $("#ASWGbillingCode").val();

        ASWGcontentType = (ASWGcontentType != "-") ? ASWGcontentType : "";
        ASWGstate = (ASWGstate != "-") ? ASWGstate : "";
        ASWGchannelConfig = (ASWGchannelConfig != "-") ? ASWGchannelConfig : "";
        ASWGambisonicChnOrder = (ASWGambisonicChnOrder != "-") ? ASWGambisonicChnOrder : "";
        ASWGambisonicNorm = (ASWGambisonicNorm != "-") ? ASWGambisonicNorm : "";
        ASWGisDesigned = (ASWGisDesigned != "-") ? ASWGisDesigned : "";
        ASWGefforts = (ASWGefforts != "-") ? ASWGefforts : "";
        ASWGprojection = (ASWGprojection != "-") ? ASWGprojection.substring(0, 1) : "";               // Fetch projection value number only
        ASWGlanguage = (ASWGlanguage != "-") ? ASWGlanguage.substring(0, 2) : "";                     // Fetch language code only
        ASWGtimingRestriction = (ASWGtimingRestriction != "-") ? ASWGtimingRestriction : "";
        ASWGcharacterRole = (ASWGcharacterRole != "-") ? ASWGcharacterRole : "";
        ASWGactorGender = (ASWGactorGender != "-") ? ASWGactorGender : "";
        ASWGisUnion = (ASWGisUnion != "-") ? ASWGisUnion : "";
        ASWGisSource = (ASWGisSource != "-") ? ASWGisSource : "";
        ASWGisLoop = (ASWGisLoop != "-") ? ASWGisLoop : "";
        ASWGisFinal = (ASWGisFinal != "-") ? ASWGisFinal : "";
        ASWGisOst = (ASWGisOst != "-") ? ASWGisOst : "";
        ASWGisCinematic = (ASWGisCinematic != "-") ? ASWGisCinematic : "";
        ASWGisLicensed = (ASWGisLicensed != "-") ? ASWGisLicensed : "";
        ASWGisDiegetic = (ASWGisDiegetic != "-") ? ASWGisDiegetic : "";

        setProjExtState(ASWGcontentType, "ASWGcontentType");
        setProjExtState(ASWGproject, "ASWGproject");
        setProjExtState(ASWGoriginatorStudio, "ASWGoriginatorStudio");
        setProjExtState(ASWGnotes, "ASWGnotes");
        setProjExtState(ASWGstate, "ASWGstate");
        setProjExtState(ASWGeditor, "ASWGeditor");
        setProjExtState(ASWGmixer, "ASWGmixer");
        setProjExtState(ASWGfxChainName, "ASWGfxChainName");
        setProjExtState(ASWGchannelConfig, "ASWGchannelConfig");
        setProjExtState(ASWGambisonicFormat, "ASWGambisonicFormat");
        setProjExtState(ASWGambisonicChnOrder, "ASWGambisonicChnOrder");
        setProjExtState(ASWGambisonicNorm, "ASWGambisonicNorm");
        setProjExtState(ASWGisDesigned, "ASWGisDesigned");
        setProjExtState(ASWGrecEngineer, "ASWGrecEngineer");
        setProjExtState(ASWGrecStudio, "ASWGrecStudio");
        setProjExtState(ASWGimpulseLocation, "ASWGimpulseLocation");
        setProjExtState(ASWGtext, "ASWGtext");
        setProjExtState(ASWGefforts, "ASWGefforts");
        setProjExtState(ASWGeffortType, "ASWGeffortType");
        setProjExtState(ASWGprojection, "ASWGprojection");
        setProjExtState(ASWGlanguage, "ASWGlanguage");
        setProjExtState(ASWGtimingRestriction, "ASWGtimingRestriction");
        setProjExtState(ASWGcharacterName, "ASWGcharacterName");
        setProjExtState(ASWGcharacterGender, "ASWGcharacterGender");
        setProjExtState(ASWGcharacterAge, "ASWGcharacterAge");
        setProjExtState(ASWGcharacterRole, "ASWGcharacterRole");
        setProjExtState(ASWGactorName, "ASWGactorName");
        setProjExtState(ASWGactorGender, "ASWGactorGender");
        setProjExtState(ASWGdirection, "ASWGdirection");
        setProjExtState(ASWGdirector, "ASWGdirector");
        setProjExtState(ASWGfxUsed, "ASWGfxUsed");
        setProjExtState(ASWGusageRights, "ASWGusageRights");
        setProjExtState(ASWGisUnion, "ASWGisUnion");
        setProjExtState(ASWGaccent, "ASWGaccent");
        setProjExtState(ASWGemotion, "ASWGemotion");
        setProjExtState(ASWGcomposer, "ASWGcomposer");
        setProjExtState(ASWGartist, "ASWGartist");
        setProjExtState(ASWGsongTitle, "ASWGsongTitle");
        setProjExtState(ASWGgenre, "ASWGgenre");
        setProjExtState(ASWGsubGenre, "ASWGsubGenre");
        setProjExtState(ASWGproducer, "ASWGproducer");
        setProjExtState(ASWGmusicSup, "ASWGmusicSup");
        setProjExtState(ASWGinstrument, "ASWGinstrument");
        setProjExtState(ASWGmusicPublisher, "ASWGmusicPublisher");
        setProjExtState(ASWGrightsOwner, "ASWGrightsOwner");
        setProjExtState(ASWGintensity, "ASWGintensity");
        setProjExtState(ASWGorderRef, "ASWGorderRef");
        setProjExtState(ASWGisSource, "ASWGisSource");
        setProjExtState(ASWGisLoop, "ASWGisLoop");
        setProjExtState(ASWGisFinal, "ASWGisFinal");
        setProjExtState(ASWGisOst, "ASWGisOst");
        setProjExtState(ASWGisCinematic, "ASWGisCinematic");
        setProjExtState(ASWGisLicensed, "ASWGisLicensed");
        setProjExtState(ASWGisDiegetic, "ASWGisDiegetic");
        setProjExtState(ASWGmusicVersion, "ASWGmusicVersion");
        setProjExtState(ASWGisrcId, "ASWGisrcId");
        setProjExtState(ASWGtempo, "ASWGtempo");
        setProjExtState(ASWGtimeSig, "ASWGtimeSig");
        setProjExtState(ASWGinKey, "ASWGinKey");
        setProjExtState(ASWGbillingCode, "ASWGbillingCode");
    }

    // GBX Mod
    if (gbxMod) {
        var gbxSuffix = $("#gbxSuffix").val();
        gbxSuffix = gbxSuffix.match(/\((.*)\)/).pop();
        setProjExtState(gbxMod, "GBXMod")
        setProjExtState(gbxSuffix, "GBXSuffix");
    } else {
        setProjExtState("false", "GBXMod")
    }

    //#endregion

    // Tell ReaScript that this is being run from a web interface
    wwr_req("SET/EXTSTATEPERSIST/UCS_WebInterface/" + "runFromWeb" + "/" + "true");

    // Run ReaScript
    wwr_req(encodeURIComponent(UCSRTLua));

    // Save current settings to history
    saveThisHistory();
});

// ~~~~~~~~~~~~~~~~~~~~
// CLICK ON TABLE ROW
// ~~~~~~~~~~~~~~~~~~~~
$('#UCRTDataTable').on('click', 'tbody tr', function () {
    var tbl = $('#UCRTDataTable').DataTable();
    var row = tbl.row($(this)).data();

    // Read settings checkboxes
    var autoSubmit = $("#autoSubmitCheckbox").prop("checked");
    var autoSearchCatSubcat = $("#autoSearchCatSubcatCheckbox").prop("checked");
    var autoSearchSynonyms = $("#autoSearchSynonymsCheckbox").prop("checked");

    // Trigger row change so form updates
    $("#userInputCategory").val(row[0]).trigger('change');
    $("select#userSelectSubCategory").val(row[1]).trigger('change');

    $("#copiedRowAlert").html("<i>Copied data to form!</i><br />Cat: <b>" + row[0] + "</b><br />Sub: <b>" + row[1] + "</b>");
    $(".copy-alert").fadeTo(4000, 500).slideUp(750);

    // Auto search media explorer (see func below)
    if (autoSearchCatSubcat && autoSearchSynonyms) searchMediaExplorer(row[2] + ", " + row[1] + ", " + row[5]); // CATsub, Sub, Syn
    else if (autoSearchCatSubcat) searchMediaExplorer(row[2]);                                                  // CATsub
    else if (autoSearchSynonyms) searchMediaExplorer(row[1] + ", " + row[5]);                                   // Sub, Syn

    // Auto submit form on row click
    if (autoSubmit) $("#formSubmitButton").click();
});

// ~~~~~~~~~~~~~~~~~~~~
// SEARCH MEDIA EXPLORER FUNCTIONS
// ~~~~~~~~~~~~~~~~~~~~
function searchMediaExplorer(search) {
    // Set project extstates from HTML vals
    setProjExtState(search, "searchMediaExplorer");

    // Run ReaScript
    wwr_req(encodeURIComponent(UCSMediaFilter));
}

// ~~~~~~~~~~~~~~~~~~~~
// REACALL
// ~~~~~~~~~~~~~~~~~~~~
function reacall() {
    // 0. Warn if not processing regions or media items
    var search_field = $("#userInputItems").val();
    switch (search_field) {
        case "Regions":
        case "Media Items":
        case "NVK Folder Items":
            break;

        case "Markers":
        case "Tracks":
        default:
            $("#dangerAlert").html("Reacall only supports Regions, Media Items, and NVK Folder Items processing targets!");
            $(".copy-alert").fadeTo(4000, 500).slideUp(750);
            return;
    }

    // 1. Set current target ext states, warn if not regions or items
    setProjExtState("userInputItems");
    setProjExtState("userInputArea");

    // 2. Run ReaScript
    wwr_req(encodeURIComponent(UCSSendToInterface));

    // 3. Wait a sec, fill form if succesful and warn if failed
    reacallHandled = false;
    wwr_req("GET/PROJEXTSTATE/UCS_WebInterface/ReacallName");
    wwr_req("GET/PROJEXTSTATE/UCS_WebInterface/ReacallMeta");

    let counter = 0;
    let timeout = 1000;
    let intervalTime = 50;
    let interval = setInterval(function () {
        // Check if response has been received
        if (reacallHandled) {
            clearInterval(interval);
        } else {
            counter++;
            // Check if timeout has been reached
            if (counter >= timeout) {
                clearInterval(interval);
                $("#dangerAlert").html("Reacall timed out while waiting for response from REAPER!");
                $(".copy-alert").fadeTo(4000, 500).slideUp(750);
            }
        }
    }, intervalTime);
}

function reacallName(ucsName) {
    const pattern = /(?<CatID>[^-_]*)-?(?<UserCategory>[^_]*)?_(?<VendorCategory>[^-]*(?=-))?-?(?<FXName>[^_]*)_(?<CreatorID>[^_]*)_(?<SourceID>[^_.]*)_?(?<UserData>[^_.]*)?\.?(?<Extension>[[:alnum:]]+)?/;
    const match = pattern.exec(ucsName);
    if (match) {
        if (jsonCatIDArr.hasOwnProperty(match.groups.CatID)) {
            document.getElementById("userInputCategory").setCustomValidity("");
            document.getElementById("userSelectSubCategory").setCustomValidity("");
            let catSubcat = jsonCatIDArr[match.groups.CatID].split(", ");
            if (catSubcat[0] !== "") $("#userInputCategory").val(catSubcat[0]).trigger('change');
            if (catSubcat[1] !== "") $("#userSelectSubCategory").val(catSubcat[1]).trigger('change');
        }

        if (match.groups.FXName && match.groups.FXName !== "") $("#userInputName").val(match.groups.FXName);
        if (match.groups.UserCategory && match.groups.UserCategory !== "") $("#userInputUserCat").val(match.groups.UserCategory);
        if (match.groups.CreatorID && match.groups.CreatorID !== "") $("#userInputInitials").val(match.groups.CreatorID);
        if (match.groups.SourceID && match.groups.SourceID !== "") $("#userInputShow").val(match.groups.SourceID);
        if (match.groups.UserData && match.groups.UserData !== "") $("#userInputData").val(match.groups.UserData);
        if (match.groups.VendorCategory && match.groups.VendorCategory !== "") $("#userInputVendCat").val(match.groups.VendorCategory);
    }
}

function reacallMeta(ucsMeta) {
    const pattern = /(?<Field>[^;=]+)=(?<Value>[^;]+);?/g;
    const matches = [...ucsMeta.matchAll(pattern)];

    for (const match of matches) {
        // console.log(`Key: ${match.groups.Field}, Value: ${match.groups.Value}`);

        switch (match.groups.Field) {
            case "TrackTitle": $("#userInputMetaTitle").val(match.groups.Value).trigger('change'); break;
            case "Description": $("#userInputMetaDesc").val(match.groups.Value).trigger('change'); break;
            case "Keywords": $("#userInputMetaKeys").val(match.groups.Value).trigger('change'); break;
            case "Microphone": $("#userInputMetaMic").val(match.groups.Value).trigger('change'); break;
            case "RecMedium": $("#userInputMetaRecMed").val(match.groups.Value).trigger('change'); break;
            case "Designer": $("#userInputMetaDsgnr").val(match.groups.Value).trigger('change'); break;
            case "Library": $("#userInputMetaLib").val(match.groups.Value).trigger('change'); break;
            case "URL": $("#userInputMetaURL").val(match.groups.Value).trigger('change'); break;
            case "Manufacturer": $("#userInputMetaManufacturer").val(match.groups.Value).trigger('change'); break;
            case "Notes": $("#metaNotes").val(match.groups.Value).trigger('change'); break;
            case "RecType": selectDropdownOptionContaining("#userInputMetaConfig", match.groups.Value); break;
            case "Location": {
                // Force visibility of manual location box
                locationChecked = true;
                localStorage.setItem("location-input-setting", locationChecked); // Set value in local storage
                $("#metaLocDiv").hide();
                $("#metaUserLocDiv").show();
                $("#userLocId").val(match.groups.Value).trigger('change');
                break;
            }
            case "MicPerspective": {
                let micPerspIntExt = match.groups.Value.split(" | ");
                selectDropdownOptionContaining("#userInputMetaPersp", micPerspIntExt[0]);
                selectDropdownOptionContaining("#userInputMetaIntExt", micPerspIntExt[1]);
                break;
            }
            // TODO: Add ASWG fields, if anyone cares...
            default: break;
        }
    }
}

function selectDropdownOptionContaining(dropdown, contains) {
    $(dropdown).find('option').each(function () {
        if ($(this).text().indexOf(contains) !== -1) {
            $(this).prop('selected', true);
            return false; // stop the loop once the desired option is found
        }
    });
}

// ~~~~~~~~~~~~~~~~~~~~
// WEB INTERFACE REQUEST HANDLER
// ~~~~~~~~~~~~~~~~~~~~
function wwr_onreply(results) {
    var ar = results.split("\n");
    var x;
    for (x = 0; x < ar.length; x++) {
        var tok = ar[x].split("\t");
        if (tok[2] == "ReacallName") {
            reacallHandled = true;
            reacallName(tok[3]);
        } else if (tok[2] == "ReacallMeta") {
            reacallHandled = true;
            reacallMeta(tok[3]);
        }
    }
}

// ~~~~~~~~~~~~~~~~~~~~
// TRIGGER SUBMIT ON ENTER KEY
// ~~~~~~~~~~~~~~~~~~~~
$(document).keydown(function (event) {
    if (event.which === 13) {
        var categoryFocused = $('#userInputCategory').is(':focus');
        var metaNotesFocused = $('#metaNotes').is(':focus');
        var modalFocused = $('body').find('.modal.show').length > 0;
        if (!categoryFocused && !modalFocused && !metaNotesFocused) {
            $("#formSubmitButton").click();
        } else if ($('#presetsModal').hasClass('show')) {
            saveThisAsPreset();
        } else if ($('#deletePresetsModal').hasClass('show')) {
            $('#deletePresetsModal').modal('hide');
            deleteThisPreset();
        } else if (modalFocused) {
            $('.modal').modal('hide');
        }
    }
});

// ~~~~~~~~~~~~~~~~~~~~
// DOWNLOAD "UCS.txt" FILE
// ~~~~~~~~~~~~~~~~~~~~
$("#downloadUCSButton").click(function (e) {
    $("#UCSInstallInstructions").show();
    $("#downloadUCSButtonText").hide();
    downloadBlobFile();
});

// ~~~~~~~~~~~~~~~~~~~~
// REENABLE ONLINE MODE INSTRUCTIONS
// ~~~~~~~~~~~~~~~~~~~~
$("#onlineUCSButton").click(function (e) {
    if (onlineModeInstructionsToggle) {
        $("#UCSOnlineModeInstructions").show();
        onlineModeInstructionsToggle = false;
        // Open Reaper resource path
        wwr_req(encodeURIComponent(REApath));
    } else {
        $("#UCSOnlineModeInstructions").hide();
        onlineModeInstructionsToggle = true;
    }
});

// ~~~~~~~~~~~~~~~~~~~~
// BUILD SUBCATEGORY ARRAY BASED ON CATEGORY
// ~~~~~~~~~~~~~~~~~~~~
$("#userInputCategory").change(function () {
    var $dropdown = $(this);
    var key = $dropdown.val();
    var vals = [];
    if (jsonCategorySubcategoryArr.hasOwnProperty(key)) {
        document.getElementById("userInputCategory").setCustomValidity("");
        document.getElementById("userSelectSubCategory").setCustomValidity("");
        vals = jsonCategorySubcategoryArr[key].split(", ");
        $("#userInputCategoryError").hide();
    } else {
        document.getElementById("userInputCategory").setCustomValidity("Invalid");
        document.getElementById("userSelectSubCategory").setCustomValidity("Invalid");
        vals = ['Please select a valid category!'];
    }

    var $secondChoice = $("#userSelectSubCategory");
    $secondChoice.empty();
    $.each(vals, function (index, value) {
        $secondChoice.append("<option>" + value + "</option>");
    });
});

// ~~~~~~~~~~~~~~~~~~~~
// SET MIC PERSPECTIVE BASED ON REC TYPE IF NEEDED/VISE VERSA
// ~~~~~~~~~~~~~~~~~~~~
$("#userInputMetaConfig").change(function () {
    var config = $("#userInputMetaConfig").val();
    if (config.includes("Contact") || config.includes("Electro") || config.includes("Hydro")) {
        $("#userInputMetaPersp").val(config);
        $("#userInputMetaIntExt").val("-").trigger('change');
    } else if (config.includes("Click to configure...")) {
        showAmbiModal();
    }
});
$("#userInputMetaPersp").change(function () {
    var config = $("#userInputMetaPersp").val();
    if (config.includes("Contact") || config.includes("Electro") || config.includes("Hydro")) {
        $("#userInputMetaConfig").val(config);
        $("#userInputMetaIntExt").val("-").trigger('change');
    }
});

// ~~~~~~~~~~~~~~~~~~~~
// AMBISONICS MODAL FUNCTIONS
// ~~~~~~~~~~~~~~~~~~~~
// Show A-Format Orientation Dropdown
$("#ambiModalFormat").change(function () {
    var config = $("#ambiModalFormat").val();
    if (config.includes("A-Format")) {
        $("#ambiModalOrientationDiv").show();
    } else {
        $("#ambiModalOrientationDiv").hide();
    }
});

// Set configuration when submit button is pressed on modal
function setAmbiConfig() {
    var ambi_order = $("#ambiModalOrder").val();
    var ambi_format = $("#ambiModalFormat").val();
    var ambi_orient = $("#ambiModalOrientation").val();
    var ambi_config = "";

    ambi_order = (ambi_order != "-") ? ambi_order.match(/\((.*)\)/).pop() : "";
    ambi_format = (ambi_format != "-") ? ambi_format.match(/\((.*)\)/).pop() : "";
    ambi_orient = (ambi_orient != "-") ? ambi_orient.match(/\((.*)\)/).pop() : "";

    if (ambi_format == "AFMT") {
        ambi_config = ambi_order + "-" + ambi_format + "-" + ambi_orient;
    } else {
        ambi_config = ambi_order + "-" + ambi_format;
    }

    ambi_config = "Ambisonic (" + ambi_config + ")"

    // Set mic config dropdown option value
    $("#customAmbi").text(ambi_config);
    $("#userInputMetaConfig").val(ambi_config).trigger('change');
}

// Show modal
function showAmbiModal() {
    $('#ambisonicsModal').modal();
}

// Make sure user didn't cancel out and leave it with "Click to configure..."
function doubleCheckAmbiConfig() {
    var meta_config = $("#userInputMetaConfig").val();
    if (meta_config.includes("configure")) {
        $("#userInputMetaConfig").val("-").trigger('change');
    }
}

// ~~~~~~~~~~~~~~~~~~~~
// BUILD SEARCH AREA OPTIONS BASED ON REGION/MARKER/ITEM/TRACK SELECTION
// ~~~~~~~~~~~~~~~~~~~~
$("#userInputItems").change(function () {
    var key = $(this).val();
    var vals = [];

    // Clean up wildcard info based on search type
    wildcardCleanup();

    switch (key) {
        case "Regions":
            // Remove selected regions option for mac users for now
            if (isMac) {
                vals = ["Edit Cursor", "Time Selection", "Full Project"];
            } else {
                vals = ["Selected Regions in Region Manager", "Edit Cursor", "Time Selection", "Full Project"];
            }
            break;

        case "Markers":
            // Remove selected markers option for mac users for now
            if (isMac) {
                vals = ["Time Selection", "Full Project"];
            } else {
                vals = ["Selected Markers in Marker Manager", "Time Selection", "Full Project"];
            }
            break;

        case "Media Items":
        case "NVK Folder Items":
            vals = ["Selected Items", "All Items"];
            break;

        case "Tracks":
            // Remove selected tracks option for mac users for now
            if (isMac) {
                vals = ["Selected Tracks", "All Tracks"];
            } else {
                vals = ["Selected Tracks", "Selected in Track Manager", "All Tracks"];
            }
            break;

        default:
            break;
    }

    // Set up search area options based on search item
    var $secondChoice = $("#userInputArea");
    $secondChoice.empty();
    $.each(vals, function (index, value) {
        $secondChoice.append("<option>" + value + "</option>");
    });
});

// ~~~~~~~~~~~~~~~~~~~~
// UPDATE NAVBAR HIGHLIGHTS W SCROLL
// ~~~~~~~~~~~~~~~~~~~~
$(window).scroll(function () {
    var removeScrollClasses = function (el1, el2, el3) {
        $(el1).removeClass("active");
        $(el2).removeClass("active");
        $(el3).removeClass("active");
    }

    var processingOffset = $("#userInputData").offset().top - $(window).scrollTop();
    var metadataOffset = $("#userInputArea").offset().top - $(window).scrollTop();
    var dataOffset = $("#formSubmitButton").offset().top - $(window).scrollTop();
    var posBuffer = 200;

    if (dataOffset < posBuffer) {
        removeScrollClasses("#metadataScroll", "#processingScroll", "#namingScroll");
        $("#dataScroll").addClass("active");

    } else if (metadataOffset < posBuffer && localStorage.getItem("metadata-setting")) {
        removeScrollClasses("#dataScroll", "#processingScroll", "#namingScroll");
        $("#metadataScroll").addClass("active");

    } else if (processingOffset < posBuffer) {
        removeScrollClasses("#metadataScroll", "#dataScroll", "#namingScroll");
        $("#processingScroll").addClass("active");

    } else {
        removeScrollClasses("#metadataScroll", "#processingScroll", "#dataScroll");
        $("#namingScroll").addClass("active");
    }
});

// ~~~~~~~~~~~~~~~~~~~~
// WILDCARD CLEANUP
// ~~~~~~~~~~~~~~~~~~~~
// Change info under file name field to match current supported wildcards
// If filename field has wildcard info that doesn't match current item selection, then change it
function wildcardCleanup() {
    var search_field = $("#userInputItems").val();
    var cur_name = $("#userInputName").val();

    var number_info = "<b>WILDCARDS: </b>";
    var closer_info = "<br />- Available wildcards are dependent on 'Items to Rename' field in <i>Processing</i> below.";

    switch (search_field) {
        case "Regions":
            // Change text below filenaming section to clarify wildcard support
            var wildcard_info = "$region, $regionnumber";
            $("#userInputNameHelp").html(number_info + wildcard_info + closer_info);

            // Naming
            if (cur_name.includes("$marker")) cur_name = cur_name.replace("$marker", "$region");
            if (cur_name.includes("$item")) cur_name = cur_name.replace("$item", "$region");
            if (cur_name.includes("$track")) cur_name = cur_name.replace("$track", "$region");

            // Numbering
            if (cur_name.includes("$markernumber")) cur_name = cur_name.replace("$markernumber", "$regionnumber");
            if (cur_name.includes("$itemnumber")) cur_name = cur_name.replace("$itemnumber", "$regionnumber");
            if (cur_name.includes("$tracknumber")) cur_name = cur_name.replace("$tracknumber", "$regionnumber");

            $("#userInputName").val(cur_name)
            break;

        case "Markers":
            var wildcard_info = "$marker, $markernumber";
            $("#userInputNameHelp").html(number_info + wildcard_info + closer_info);

            if (cur_name.includes("$region")) cur_name = cur_name.replace("$region", "$marker");
            if (cur_name.includes("$item")) cur_name = cur_name.replace("$item", "$marker");
            if (cur_name.includes("$track")) cur_name = cur_name.replace("$track", "$marker");

            if (cur_name.includes("$regionnumber")) cur_name = cur_name.replace("$regionnumber", "$markernumber");
            if (cur_name.includes("$itemnumber")) cur_name = cur_name.replace("$itemnumber", "$markernumber");
            if (cur_name.includes("$tracknumber")) cur_name = cur_name.replace("$tracknumber", "$markernumber");

            $("#userInputName").val(cur_name)
            break;

        case "Media Items":
        case "NVK Folder Items":
            var wildcard_info = "$item, $itemnumber";
            $("#userInputNameHelp").html(number_info + wildcard_info + closer_info);

            if (cur_name.includes("$marker")) cur_name = cur_name.replace("$marker", "$item");
            if (cur_name.includes("$region")) cur_name = cur_name.replace("$region", "$item");
            if (cur_name.includes("$track")) cur_name = cur_name.replace("$track", "$item");

            if (cur_name.includes("$markernumber")) cur_name = cur_name.replace("$markernumber", "$itemnumber");
            if (cur_name.includes("$regionnumber")) cur_name = cur_name.replace("$regionnumber", "$itemnumber");
            if (cur_name.includes("$tracknumber")) cur_name = cur_name.replace("$tracknumber", "$itemnumber");

            $("#userInputName").val(cur_name)
            break;

        case "Tracks":
            var wildcard_info = "$track, $tracknumber";
            $("#userInputNameHelp").html(number_info + wildcard_info + closer_info);

            if (cur_name.includes("$marker")) cur_name = cur_name.replace("$marker", "$track");
            if (cur_name.includes("$item")) cur_name = cur_name.replace("$item", "$track");
            if (cur_name.includes("$region")) cur_name = cur_name.replace("$region", "$track");

            if (cur_name.includes("$markernumber")) cur_name = cur_name.replace("$markernumber", "$tracknumber");
            if (cur_name.includes("$itemnumber")) cur_name = cur_name.replace("$itemnumber", "$tracknumber");
            if (cur_name.includes("$regionnumber")) cur_name = cur_name.replace("$regionnumber", "$tracknumber");

            $("#userInputName").val(cur_name)
            break;

        default:
            break;
    }
}

// ~~~~~~~~~~~~~~~~~~~~
// VALIDATE ALL FIELDS ON KEYPRESS
// ~~~~~~~~~~~~~~~~~~~~
$("input[type='text']").change(function () {
    // Delayed form check to allow for default preset load
    var loadedSeconds = (new Date().valueOf() - startTime) / 1000;
    if (loadedSeconds > 1 && event) {
        // validateCategory();
        // Fetch form to apply custom Bootstrap validation
        var form = $("#ucsForm");
        if (form[0].checkValidity() === false) {
            // Form is invalid
            event.preventDefault();
            event.stopPropagation();
        }
        form.addClass('was-validated');

        if ($('#ASWGInfoModal').hasClass('show')) {
            form = $("#ASWGInfoForm");
            if (form[0].checkValidity() === false) {
                event.preventDefault();
                event.stopPropagation();
            } else {
                $("#ASWGInfoFormError").hide();
            }
            form.addClass('was-validated');

        } else if ($('#ASWGMusicModal').hasClass('show')) {
            form = $("#ASWGMusicForm");
            if (form[0].checkValidity() === false) {
                event.preventDefault();
                event.stopPropagation();
            } else {
                $("#ASWGMusicFormError").hide();
            }
            form.addClass('was-validated');

        } else if ($('#ASWGDialogueModal').hasClass('show')) {
            form = $("#ASWGDialogueForm");
            if (form[0].checkValidity() === false) {
                event.preventDefault();
                event.stopPropagation();
            } else {
                $("#ASWGDialogueFormError").hide();
            }
            form.addClass('was-validated');
        }
    }
});

// ~~~~~~~~~~~~~~~~~~~~
// VALIDATE NAME FIELD
// ~~~~~~~~~~~~~~~~~~~~
$("#userInputName").keyup(function () {
    if (document.getElementById("userInputName").checkValidity() === true) {
        $("#userInputNameError").hide();
    }
});

// ~~~~~~~~~~~~~~~~~~~~
// VALIDATE INITIALS FIELD
// ~~~~~~~~~~~~~~~~~~~~
$("#userInputInitials").keyup(function () {
    if (document.getElementById("userInputInitials").checkValidity() === true) {
        $("#userInitialsError").hide();
    }
});

// ~~~~~~~~~~~~~~~~~~~~
// COPY WITHOUT PROCESSING ALERT
// ~~~~~~~~~~~~~~~~~~~~
$("#copyResultsSetting").change(function () {
    var key = $(this).val();
    localStorage.setItem("copy-setting", key); // Set value in local storage
    if (key == "Copy WITHOUT processing") {
        $("#copyResultsWarning").show();
        $("#copyResultsWarning2").show();
    } else {
        $("#copyResultsWarning").hide();
        $("#copyResultsWarning2").hide();
    }
});

// ~~~~~~~~~~~~~~~~~~~~
// ASWG Content Type
// ~~~~~~~~~~~~~~~~~~~~
$("#ASWGcontentType").change(function () {
    var key = $(this).val();
    if (key == "SFX") {
        $("#ASWGInfoBtn").show();
        //$("#ASWGSFXBtn").show();
        $("#ASWGMusicBtn").hide();
        $("#ASWGDialogueBtn").hide();
        $("#ASWGimpulseLocationSection").hide();
    } else if (key == "Music") {
        $("#ASWGInfoBtn").show();
        //$("#ASWGSFXBtn").hide();
        $("#ASWGMusicBtn").show();
        $("#ASWGDialogueBtn").hide();
        $("#ASWGimpulseLocationSection").hide();
    } else if (key == "Dialogue") {
        $("#ASWGInfoBtn").show();
        //$("#ASWGSFXBtn").hide();
        $("#ASWGMusicBtn").hide();
        $("#ASWGDialogueBtn").show();
        $("#ASWGimpulseLocationSection").hide();
    } else if (key == "Mixed") {
        $("#ASWGInfoBtn").show();
        //$("#ASWGSFXBtn").show();
        $("#ASWGMusicBtn").show();
        $("#ASWGDialogueBtn").show();
        $("#ASWGimpulseLocationSection").show();
    } else if (key == "Impulse (IR)") {
        $("#ASWGInfoBtn").show();
        //$("#ASWGSFXBtn").hide();
        $("#ASWGMusicBtn").hide();
        $("#ASWGDialogueBtn").hide();
        $("#ASWGimpulseLocationSection").show();
    } else if (key == "Haptic") {
        $("#ASWGInfoBtn").show();
        //$("#ASWGSFXBtn").hide();
        $("#ASWGMusicBtn").hide();
        $("#ASWGDialogueBtn").hide();
        $("#ASWGimpulseLocationSection").hide();
    } else {
        $("#ASWGInfoBtn").hide();
        //$("#ASWGSFXBtn").hide();
        $("#ASWGMusicBtn").hide();
        $("#ASWGDialogueBtn").hide();
        $("#ASWGimpulseLocationSection").hide();
    }
});

// ~~~~~~~~~~~~~~~~~~~~
// ASWG Ambisonic Channels
// ~~~~~~~~~~~~~~~~~~~~
$("#ASWGchannelConfig").change(function () {
    var key = $(this).val();
    if (key == "Ambisonic") {
        $("#ASWGambisonicFormatSection").show();
        $("#ASWGambisonicChnOrderSection").show();
        $("#ASWGambisonicNormSection").show();
    } else {
        $("#ASWGambisonicFormatSection").hide();
        $("#ASWGambisonicChnOrderSection").hide();
        $("#ASWGambisonicNormSection").hide();
    }
});

// ~~~~~~~~~~~~~~~~~~~~
// UCS iXML RENDERING ON CHANGE
// ~~~~~~~~~~~~~~~~~~~~
$("#iXMLSettings").change(function () {
    var iXMLChecked = $(this).prop("checked");
    if (iXMLChecked) {
        localStorage.setItem("ixml-setting", iXMLChecked); // Set value in local storage
        $("#metadataWarning").show();
    } else {
        localStorage.removeItem("ixml-setting");
        if (!$("#metadataSettings").prop("checked")) {
            $("#metadataWarning").hide();
        }
    }
});

// ~~~~~~~~~~~~~~~~~~~~
// RENDER DIRECTORY SETTINGS ON CHANGE
// ~~~~~~~~~~~~~~~~~~~~
$("#renderDirectorySettings").change(function () {
    var directoryChecked = $(this).prop("checked");
    if (directoryChecked) {
        localStorage.setItem("directory-setting", directoryChecked); // Set value in local storage
    } else {
        localStorage.removeItem("directory-setting");
    }
});

// ~~~~~~~~~~~~~~~~~~~~
// LOCATION INPUT SETTINGS ON CHANGE
// ~~~~~~~~~~~~~~~~~~~~
$("#locationInputSettings").change(function () {
    var locationChecked = $(this).prop("checked");
    if (locationChecked) {
        localStorage.setItem("location-input-setting", locationChecked); // Set value in local storage
        $("#metaLocDiv").hide();
        $("#metaUserLocDiv").show();
    } else {
        localStorage.removeItem("location-input-setting");
        $("#metaLocDiv").show();
        $("#metaUserLocDiv").hide();
    }
});

// ~~~~~~~~~~~~~~~~~~~~
// MARKER POSITION SETTINGS ON CHANGE
// ~~~~~~~~~~~~~~~~~~~~
$("#markerPositionSettings").change(function () {
    var markerPosChecked = $(this).prop("checked");
    if (markerPosChecked) {
        localStorage.setItem("marker-pos-setting", markerPosChecked); // Set value in local storage
    } else {
        localStorage.removeItem("marker-pos-setting");
    }
});

// ~~~~~~~~~~~~~~~~~~~~
// EXTENDED METADATA TOGGLE ON CHANGE
// ~~~~~~~~~~~~~~~~~~~~
$("#metadataSettings").change(function () {
    var metadataChecked = $(this).prop("checked");
    if (metadataChecked) {
        localStorage.setItem("metadata-setting", metadataChecked);
        $("#metadataWarning").show();
        $("#metadataTitle").show();
        $("#metadataSection").show();
        $("#metadataScroll").show();
    } else {
        localStorage.removeItem("metadata-setting");
        $("#metadataTitle").hide();
        $("#metadataSection").hide();
        $("#metadataScroll").hide();
        if (!$("#iXMLSettings").prop("checked")) {
            $("#metadataWarning").hide();
        }
    }
})

// ~~~~~~~~~~~~~~~~~~~~
// ASWG METADATA TOGGLE ON CHANGE
// ~~~~~~~~~~~~~~~~~~~~
$("#ASWGSettings").change(function () {
    var aswgChecked = $(this).prop("checked");
    if (aswgChecked) {
        localStorage.setItem("aswg-setting", aswgChecked);
        $("#ASWGSection").show();
    } else {
        localStorage.removeItem("aswg-setting");
        $("#ASWGSection").hide();
    }
})

// ~~~~~~~~~~~~~~~~~~~~
// VENDOR CAT CHECKBOX TOGGLE ON CHANGE
// ~~~~~~~~~~~~~~~~~~~~
$("#vendorCatCheckbox").change(function () {
    var vendorCatChecked = $(this).prop("checked");
    if (vendorCatChecked) {
        localStorage.setItem("vendor-cat-setting", vendorCatChecked);
        $("#vendorCategoryGroup").show();
    } else {
        localStorage.removeItem("vendor-cat-setting");
        $("#vendorCategoryGroup").hide();
    }
})

// ~~~~~~~~~~~~~~~~~~~~
// LOG ALBUM ART ON INPUT CHANGE
// ~~~~~~~~~~~~~~~~~~~~
$("#userInputMetaArt").on("change", function () {
    var fullName = $(this).file().name[0];
    var fileName = $(this).val().split("\\").pop();
    console.log(fullName);
    console.log(fileName);
});

// ~~~~~~~~~~~~~~~~~~~~
// STORE CAPITALIZATION SETTINGS
// ~~~~~~~~~~~~~~~~~~~~
$("#nameCapitalizationSetting").change(function () {
    var key = $(this).val();
    localStorage.setItem("caps-setting", key); // Set value in local storage
});

// ~~~~~~~~~~~~~~~~~~~~
// FX NAME FORMAT SETTINGS
// ~~~~~~~~~~~~~~~~~~~~
$("#fxFormattingSetting").change(function () {
    var key = $(this).val();
    localStorage.setItem("fx-format-setting", key); // Set value in local storage
});

// ~~~~~~~~~~~~~~~~~~~~
// SET LANGUAGE - English
// ~~~~~~~~~~~~~~~~~~~~
$("#langEN").click(function (e) {
    localStorage.setItem("ucs_language", ucs_gsheet_en);
    localStorage.setItem("ucs_language_country", "us");
    location.reload();
});

// ~~~~~~~~~~~~~~~~~~~~
// SET LANGUAGE - Spanish
// ~~~~~~~~~~~~~~~~~~~~
$("#langES").click(function (e) {
    localStorage.setItem("ucs_language", ucs_gsheet_es);
    localStorage.setItem("ucs_language_country", "es");
    location.reload();
});

// ~~~~~~~~~~~~~~~~~~~~
// SET LANGUAGE - French
// ~~~~~~~~~~~~~~~~~~~~
$("#langFR").click(function (e) {
    localStorage.setItem("ucs_language", ucs_gsheet_fr);
    localStorage.setItem("ucs_language_country", "fr");
    location.reload();
});

// ~~~~~~~~~~~~~~~~~~~~
// SET LANGUAGE - German
// ~~~~~~~~~~~~~~~~~~~~
$("#langDE").click(function (e) {
    localStorage.setItem("ucs_language", ucs_gsheet_de);
    localStorage.setItem("ucs_language_country", "de");
    location.reload();
});

// ~~~~~~~~~~~~~~~~~~~~
// SET LANGUAGE - Italian
// ~~~~~~~~~~~~~~~~~~~~
$("#langIT").click(function (e) {
    localStorage.setItem("ucs_language", ucs_gsheet_it);
    localStorage.setItem("ucs_language_country", "it");
    location.reload();
});

// ~~~~~~~~~~~~~~~~~~~~
// SET LANGUAGE - Polish
// ~~~~~~~~~~~~~~~~~~~~
$("#langPL").click(function (e) {
    localStorage.setItem("ucs_language", ucs_gsheet_pl);
    localStorage.setItem("ucs_language_country", "pl");
    location.reload();
});

// ~~~~~~~~~~~~~~~~~~~~
// SET LANGUAGE - Dutch
// ~~~~~~~~~~~~~~~~~~~~
$("#langNL").click(function (e) {
    localStorage.setItem("ucs_language", ucs_gsheet_nl);
    localStorage.setItem("ucs_language_country", "nl");
    location.reload();
});

// ~~~~~~~~~~~~~~~~~~~~
// SET LANGUAGE - Danish
// ~~~~~~~~~~~~~~~~~~~~
$("#langDA").click(function (e) {
    localStorage.setItem("ucs_language", ucs_gsheet_da);
    localStorage.setItem("ucs_language_country", "dk");
    location.reload();
});

// ~~~~~~~~~~~~~~~~~~~~
// SET LANGUAGE - Finnish
// ~~~~~~~~~~~~~~~~~~~~
$("#langFI").click(function (e) {
    localStorage.setItem("ucs_language", ucs_gsheet_fi);
    localStorage.setItem("ucs_language_country", "fi");
    location.reload();
});

// ~~~~~~~~~~~~~~~~~~~~
// SET LANGUAGE - Portuguese
// ~~~~~~~~~~~~~~~~~~~~
$("#langPT").click(function (e) {
    localStorage.setItem("ucs_language", ucs_gsheet_pt);
    localStorage.setItem("ucs_language_country", "pt");
    location.reload();
});

// ~~~~~~~~~~~~~~~~~~~~
// SET LANGUAGE - Portuguese - Brazil
// ~~~~~~~~~~~~~~~~~~~~
$("#langPTBR").click(function (e) {
    localStorage.setItem("ucs_language", ucs_gsheet_pt_br);
    localStorage.setItem("ucs_language_country", "br");
    location.reload();
});

// ~~~~~~~~~~~~~~~~~~~~
// SET LANGUAGE - Chinese
// ~~~~~~~~~~~~~~~~~~~~
$("#langZH").click(function (e) {
    localStorage.setItem("ucs_language", ucs_gsheet_zh);
    localStorage.setItem("ucs_language_country", "cn");
    location.reload();
});

// ~~~~~~~~~~~~~~~~~~~~
// SET LANGUAGE - Japanese
// ~~~~~~~~~~~~~~~~~~~~
$("#langJA").click(function (e) {
    localStorage.setItem("ucs_language", ucs_gsheet_ja);
    localStorage.setItem("ucs_language_country", "jp");
    location.reload();
});

// ~~~~~~~~~~~~~~~~~~~~
// SET LANGUAGE - Taiwan
// ~~~~~~~~~~~~~~~~~~~~
$("#langTW").click(function (e) {
    localStorage.setItem("ucs_language", ucs_gsheet_tw);
    localStorage.setItem("ucs_language_country", "tw");
    location.reload();
});

// ~~~~~~~~~~~~~~~~~~~~
// SET LANGUAGE - Korean
// ~~~~~~~~~~~~~~~~~~~~
$("#langKR").click(function (e) {
    localStorage.setItem("ucs_language", ucs_gsheet_kr);
    localStorage.setItem("ucs_language_country", "kr");
    location.reload();
});

// ~~~~~~~~~~~~~~~~~~~~
// SET LANGUAGE - Norway
// ~~~~~~~~~~~~~~~~~~~~
$("#langNO").click(function (e) {
    localStorage.setItem("ucs_language", ucs_gsheet_no);
    localStorage.setItem("ucs_language_country", "no");
    location.reload();
});

// ~~~~~~~~~~~~~~~~~~~~
// SET LANGUAGE - Sweden
// ~~~~~~~~~~~~~~~~~~~~
$("#langSE").click(function (e) {
    localStorage.setItem("ucs_language", ucs_gsheet_se);
    localStorage.setItem("ucs_language_country", "se");
    location.reload();
});

// ~~~~~~~~~~~~~~~~~~~~
// SET LANGUAGE - Russian
// ~~~~~~~~~~~~~~~~~~~~
$("#langRU").click(function (e) {
    localStorage.setItem("ucs_language", ucs_gsheet_ru);
    localStorage.setItem("ucs_language_country", "ru");
    location.reload();
});

// ~~~~~~~~~~~~~~~~~~~~
// SET LANGUAGE - Ukrainian
// ~~~~~~~~~~~~~~~~~~~~
$("#langUA").click(function (e) {
    localStorage.setItem("ucs_language", ucs_gsheet_ua);
    localStorage.setItem("ucs_language_country", "ua");
    location.reload();
});

// ~~~~~~~~~~~~~~~~~~~~
// SET LANGUAGE - Turkish
// ~~~~~~~~~~~~~~~~~~~~
$("#langTR").click(function (e) {
    localStorage.setItem("ucs_language", ucs_gsheet_tr);
    localStorage.setItem("ucs_language_country", "tr");
    location.reload();
});

// ~~~~~~~~~~~~~~~~~~~~
// GET UCS LANGUAGE COUNTRY ICON
// ~~~~~~~~~~~~~~~~~~~~
function getUCSLanguage() {
    // Parse JSON from Google Sheet
    var ucs_lang_country = "";
    if (localStorage.getItem("ucs_language_country") !== null) {
        ucs_lang_country = localStorage.getItem("ucs_language_country");
    } else {
        // Default to English/US
        localStorage.setItem("ucs_language_country", "us");
        ucs_lang_country = "us";
    }
    $("#navbarLangDropdown").html('<i class="flag ' + ucs_lang_country + '"></i>&nbsp;&nbsp;Language');

    // Set HTML per language
    switch (ucs_lang_country) {
        case "cn":
            // Relabel fields for Chinese. Thanks 崔强强!

            // Navbar
            $("#navbarTitle").html("&nbsp;UCS Reaper 重命名工具");
            $("#namingScroll").html('<a class="nav-link" href="#">命名<span class="sr-only">(current)</span></a>');
            $("#processingScroll").html('<a class="nav-link" href="#userInputData">处理</a>');
            $("#metadataScroll").html('<a class="nav-link" href="#userInputArea">元数据</a>');
            $("#dataScroll").html('<a class="nav-link" href="#formSubmitButton">UCS 在线数据库</a>');
            $("#navbarPresetsDropdown").text('预设');
            $("#navbarHistoryDropdown").text('历史');
            $("#navbarLangDropdown").text('数据库语言（请选择中文）');
            $("#langEN").html('<i class="flag us"></i>&nbsp;&nbsp;英文');
            $("#langES").html('<i class="flag es"></i>&nbsp;&nbsp;西班牙语');
            $("#langFR").html('<i class="flag fr"></i>&nbsp;&nbsp;法语');
            $("#langDE").html('<i class="flag de"></i>&nbsp;&nbsp;德语');
            $("#langIT").html('<i class="flag it"></i>&nbsp;&nbsp;意大利语');
            $("#langPL").html('<i class="flag pl"></i>&nbsp;&nbsp;波兰语');
            $("#langNL").html('<i class="flag nl"></i>&nbsp;&nbsp;荷兰语');
            $("#langDA").html('<i class="flag dk"></i>&nbsp;&nbsp;丹麦语');
            $("#langNO").html('<i class="flag no"></i>&nbsp;&nbsp;挪威语');
            $("#langSE").html('<i class="flag se"></i>&nbsp;&nbsp;瑞典');
            $("#langFI").html('<i class="flag fi"></i>&nbsp;&nbsp;芬兰语');
            $("#langPT").html('<i class="flag pt"></i>&nbsp;&nbsp;葡萄牙语');
            $("#langPTBR").html('<i class="flag br"></i>&nbsp;&nbsp;葡萄牙语-巴西');
            $("#langZH").html('<i class="flag cn"></i>&nbsp;&nbsp;简体中文');
            $("#langJA").html('<i class="flag jp"></i>&nbsp;&nbsp;日语');
            $("#langTW").html('<i class="flag tw"></i>&nbsp;&nbsp;繁体中文');
            $("#langKR").html('<i class="flag kr"></i>&nbsp;&nbsp;韩国人');
            $("#langRU").html('<i class="flag ru"></i>&nbsp;&nbsp;俄语');
            $("#langUA").html('<i class="flag ua"></i>&nbsp;&nbsp;乌克兰语');
            $("#langTR").html('<i class="flag tr"></i>&nbsp;&nbsp;土耳其');

            // Settings menu
            $("#settingsBtnDark").html('<img src="ucs_libraries/settings-icon-dark.png" width="25" height="25" class="d-inline-block align-top" alt="">&nbsp;工具设置');
            $("#settingsBtnLight").html('<img src="ucs_libraries/settings-icon-light.png" width="25" height="25" class="d-inline-block align-top" alt="">&nbsp;工具设置');
            $("#settingsMenuTitle").text('UCS 重命名工具设置');
            $("#settingsMenuProcessingTitle").html('<i>处理数据</i>');
            $("#settingsVendorHeader").text('供应商类别：');
            $("#settingsVendorDescription").text('显示供应商类别字段？（只与音效库供应商相关）');
            $("#settingsCapsHeader").text('自动大写：');
            $("#settingsCapsDesc").text('创建者ID，源ID，用户类别，供应商类别：');
            $("#nameCapitalizationSetting").html('<option>全部大写 （默认）</option><option>标题大写</option><option>禁用自动大写</option>');
            $("#settingsCopyHeader").text('名称复制设置:');
            $("#copyResultsSetting").html('<option>无需复制（默认）</option><option>处理数据后复制</option><option>无需处理即可复制</option>');
            $("#copyResultsWarning").text('此处设置可以绕过处理部分和只需复制到剪贴板.');
            $("#settingsUCSTableHeader").text('UCS 在线数据库');
            $("#settingsUCSAutoSubmit").text('自动提交：');
            $("#settingsUCSAutoSubmitDesc").text('单击表格行时自动提交表单数据？');
            $("#settingsFilterMediaExp").text('过滤媒体资源管理器：');
            $("#settingsFilterMediaExpDesc").text('单击表格行时在媒体资源管理器中搜索类别/子类别？ ');
            $("#settingsFilterMediaExpSyn").text('单击表格行时在媒体资源管理器中搜索同义词？');
            $("#settingsMetadataHeader").text('元数据');
            $("#settingsUCSMetadataHeader").text('渲染UCS元数据');
            $("#settingsUCSMetadataDesc").text('渲染时在元数据中嵌入 UCS 表单信息？');
            $("#settingsExtMetaHeader").text('显示扩展的元数据输入字段，如麦克风，视角，位置等。');
            $("#metadataWarning").html('- 渲染元数据需要在渲染设置中检查“嵌入：元数据”<br>- 重命名轨道时渲染元数据 <b>不适用</b>。 <br>- 渲染元数据字段都是可选的，可以留空。');
            $("#settingsAppearanceHeader").text('外观/风格：');
            $("#settingsLightModeButton").html('<img src="ucs_libraries/light-mode-icon.png" width="25" height="25" class="d-inline-block align-top" alt="">&nbsp;白色模式');
            $("#settingsDarkModeButton").html('<img src="ucs_libraries/dark-mode-icon.png" width="25" height="25" class="d-inline-block align-top" alt="">&nbsp;黑色模式');
            $("#settingsLinksHeader").text('外部链接');
            $("#settingsLightFdbk").html('<img src="ucs_libraries/dark-feedback-icon.png" width="25" height="25" class="d-inline-block align-top" alt="">&nbsp;反馈');
            $("#settingsDarkFdbk").html('<img src="ucs_libraries/light-feedback-icon.png" width="25" height="25" class="d-inline-block align-top" alt="">&nbsp;反馈');
            $("#settingsLightUCS").html('<img src="ucs_libraries/ucs_logo_white_on_black.png" width="25" height="25" class="d-inline-block align-top" alt="">&nbsp;UCS 官网');
            $("#settingsDarkUCS").html('<img src="ucs_libraries/ucs_logo_black_on_white.png" width="25" height="25" class="d-inline-block align-top" alt="">&nbsp;UCS 官网');
            $("#settingsFooter").html('<p class="mr-auto">由&nbsp;<a href="https://aaroncendan.me" target="_blank">Aaron Cendan</a>开发，请作者&nbsp;<a href="https://ko-fi.com/acendan_" target="_blank">喝杯咖啡！</a> <br/>此界面是由<a href="http://wpa.qq.com/pa?p=2:524541577:41" target="_blank">52HZ Studio</a>修改的中文分支!</p><button type="button" class="btn btn-secondary" data-dismiss="modal">关闭设置</button>');
            $("#savePresetModalContent").html('<div class="modal-header"><h3 style="margin:0;" class="modal-title">保存当前设置</h4></div><div class="modal-body"><label for="presetNameLabel">预设名称</label><input type="text" class="form-control" id="presetName" aria-describedby="presetNameHelp" placeholder="我的预设"><small id="presetNameHelp" class="form-text text-muted">- 一个名为“Default”的预设会在你打开工具时加载<br>- 预设将收集所有字段信息。 <br>- 我建议将“类别”、“子类别”和“文件名”留空。</br></small></div><div class="modal-footer"><button type="button" class="btn btn-success" onClick="saveThisAsPreset()" data-dismiss="modal">保存</button><button type="button" class="btn btn-secondary" data-dismiss="modal">关闭</button></div>');
            $("#deletePresetModalContent").html('<div class="modal-header"><h3 style="margin:0;" class="modal-title">删除预设</h4></div><div class="modal-body"><label for="presetNameLabel">删除预设...</label><select id="deletePresetSelect" class="form-control"></select><small class="form-text text-muted"><b>警告: </b>删除后无法还原预设.</small></div><div class="modal-footer"><button type="button" class="btn btn-danger" onClick="deleteThisPreset()" data-dismiss="modal">删除预设</button><button type="button" class="btn btn-secondary" data-dismiss="modal">关闭</button></div>');

            // Form
            $("#naming").html('<i>UCS命名</i>');
            $("#namingFormRow").html('<!-- Category --><div class="form-group col-md-6 required" id="typeaheadCategory"><label for="userInputCategoryLabel">类别*（必填项）</label><br><input type="text" class="form-control typeahead" id="userInputCategory" aria-describedby="userInputCategoryHelp" placeholder="这是什么声音类型?" required><div id="userInputCategoryError" style="display: none; margin:0;" class="alert alert-warning" role="alert">No valid CatID found. Please check your Category & Subcategory selections!</div><small id="userInputCategoryHelp" class="form-text text-muted">输入即可自动搜索类别，也可点击数据库查询。</small></div><!-- Subcategory --><div class="form-group col-md-6 required" id="typeaheadSubcategory"><label for="userInputSubCategoryLabel">子类别*（必填项）</label><select class="form-control" id="userSelectSubCategory" required><option>请选择一个类别!</option></select><small id="userInputSubCategoryHelp" class="form-text text-muted">选择类别时，子类别下拉列表将填充选项。 如果不需要子类别选择“-” </small>                </div>                <!-- User Category -->                <div class="form-group col-md-6" id="userCategoryGroup"><label for="userInputUserCatLabel">用户类别（可选）</label><input type="text" class="form-control" id="userInputUserCat" aria-describedby="userInputUserCatHelp" placeholder="可选用户类别 "><small id="userInputUserCatHelp" class="form-text text-muted">如果没有“用户类别” 请留空</small>                </div>                <!-- Vendor Category -->                <div class="form-group col-md-6" id="vendorCategoryGroup"><label for="userInputVendCatLabel">供应商名称（可选）</label><input type="text" class="form-control" id="userInputVendCat" aria-describedby="userInputVendCatHelp" placeholder="可选音效库类别 "><small id="userInputVendCatHelp" class="form-text text-muted">如果您不是音效库供应商，请留空。</small>                </div>                <!-- Name w Var ID -->                <div class="form-group col-md-6 required" id="fileNameGroup"><label for="userInputNameLabel">文件名*</label><input type="text" class="form-control" id="userInputName" aria-describedby="userInputNameHelp" placeholder="使用空格（而不是下划线）命名您的项目。" required pattern="(.|\s)*\S(.|\s)*"><div id="userInputNameError" style="display: none; margin:0;" class="alert alert-warning" role="alert">文件名不能为空!</div><div class="form-check" style="margin-left:0px"><input class="form-check-input" type="checkbox" checked id="userInputVarNumCheckbox"><h7>需要改变编号吗？</h7></div><small id="userInputNameHelp" class="form-text text-muted"><b>通配符： </b>$region, $regionnumber<br />- 可用的通配符取决于中的“要重命名的项目”字段 <i>处理（Processing）</i> 以下（below）。</small>                </div>                <!-- Initials -->                <div class="form-group col-md-6" id="initialsGroup"><label for="userInputInitialsLabel">作者名称*</label><input type="text" class="form-control" id="userInputInitials" aria-describedby="userInputInitialsHelp" placeholder="可识别的用户名称或标签" required pattern=".{1,}"><div id="userInitialsError" style="display: none; margin:0;" class="alert alert-warning" role="alert">首字母不能为空!</div><small id="userInputInitialsHelp" class="form-text text-muted">例如"张三" => "ZS"或者"zhangsan"   也可以填写英文名（无法确定版权的建议此处可以做特殊标记）</small>                </div>                <!-- Show -->                <div class="form-group col-md-6"><label for="userInputShowLabel">项目名称（可选）</label><input type="text" class="form-control" id="userInputShow" aria-describedby="userInputShowHelp" placeholder="您正在从事什么项目？"><small id="userInputShowHelp" class="form-text text-muted">如果没有项目，则留空； 根据 UCS 指南，它将自动替换为“NONE”。 （此项目非剪辑项目）</small></div><!-- User Data --><div class="form-group col-md-6"><label for="userDataLabel">数据/注释（可选）</label><input type="text" class="form-control" id="userInputData" aria-describedby="userInputDataHelp" placeholder="麦克风、视角、位置或其他。"><small id="userInputDataHelp" class="form-text text-muted">您还有什么要补充的吗？ 如果没有注释，请留空。</small></div>');
            $("#processing").html('<i>处理</i>');
            $("#processingFormRow").html('<div id="copyResultsWarning2" style="display: none;" class="alert alert-warning" role="alert">You currently have "Copy WITHOUT processing" enabled in the settings. Results will be copied to the clipboard, but nothing will be renamed in your session.</div><div class="form-group col-md-6"><h7>要重命名的项目*</h7><select id="userInputItems" class="form-control"><option>区域</option><option>标记</option><option>媒体项目</option><option>轨道</option></select><small id="userInputCategoryHelp" class="form-text text-muted">你想重命名什么？</small></div><div class="form-group col-md-6"><h7>搜索区域*</h7><select id="userInputArea" class="form-control"><option>区域管理器中的选定区域</option><option>编辑光标</option><option>时间选择</option><option>完整项目</option></select><small id="userInputCategoryHelp" class="form-text text-muted">选择您想要影响的项目区域。</small></div>');
            $("#metadataTitle").html('<i>元数据</i>');
            $("#metaDescDiv").html('<label for="userDataLabel">描述</label><input type="text" class="form-control" id="userInputMetaDesc" placeholder="文件内容的完整详细说明">');
            $("#metaTitleDiv").html('<div class="form-group col-md-4" style="margin-left: 15px; margin-right: 15px;"><label for="userDataLabel">标题</label><input type="text" class="form-control" id="userInputMetaTitle" placeholder="简短的标题"></div><div class="form-group col-md-4" style="margin-left: 0px"><label for="userDataLabel">关键词</label><input type="text" class="form-control" id="userInputMetaKeys" placeholder="逗号、分隔符、关键字、标签"></div>');
            $("#metaMicDiv").html('<div class="form-group col-md-4" style="margin-left: 15px; margin-right: 15px;"><label for="userDataLabel">麦克风</label><input type="text" class="form-control" id="userInputMetaMic" placeholder="Mini MS"></div><div class="form-group col-md-4" style="margin-left: 0px"><label for="userDataLabel">录音设备(AD转换工具)</label><input type="text" class="form-control" id="userInputMetaRecMed"></div>');
            $("#metaDsgnDiv").html('<div class="form-group col-md-3" style="margin-left: 15px; margin-right: 15px;"><label for="userDataLabel">设计师</label><input type="text" class="form-control" id="userInputMetaDsgnr" placeholder="例如：张三"></div><div class="form-group col-md-3" style="margin-left: 0px"><label for="userDataLabel">信息库（日期）</label><input type="text" class="form-control" id="userInputMetaLib" placeholder="2021年7月"></div><div class="form-group col-md-3" style="margin-left: 0px"><label for="userDataLabel">URL</label><input type="text" class="form-control" id="userInputMetaURL" placeholder="https://aaroncendan.me"></div>');
            $("#userInputMetaPersp").html('<option>-</option><option>近距离 (CU)</option><option>中等距离 (MED)</option><option>远距离 (DST)</option><option>直接 (DI)</option><option>板载 (OB)</option><option>Various (VARI)</option><option disabled></option><option disabled><i>Specialty</i></option>   <option>Contact (CNTCT)</option><option>Hydrophone (HYDRO)</option><option>Electromagnetic (EMF)</option>');
            $("#metaIntExtDiv").html('<label for="userDataLabel">室内/室外</label><select id="userInputMetaIntExt" class="form-control" style="margin-top: 0px;"><option>-</option><option>室内 (INT)</option><option>室外 (EXT)</option></select>');
            $("#metaMicPerspLabel").text('麦克风角度');
            $("#metaLocDiv").html('<!-- Country --><div class="form-group col-md-3" style="margin-left: 15px; margin-right: 15px;"><label for="userDataLabel" style="margin-bottom: 0px;">地点</label><select name="country" class="form-control countries order-alpha" id="countryId"><option value="">选择国家/地区</option></select><small class="form-text text-muted">国家/地区</small></div><!-- State --><div class="form-group col-md-3" style="margin-left: 0px; margin-top: 35px;"><select name="state" class="form-control states order-alpha" id="stateId"><option value="">选择省份</option></select><small class="form-text text-muted">省份</small></div><!-- City --><div class="form-group col-md-3" style="margin-left: 0px; margin-top: 35px;"><select name="city" class="form-control cities order-alpha limit-pop-10000" id="cityId"><option value="">选择城市</option></select><small class="form-text text-muted">城市</small></div>');
            $("#formSubmitButton").html('<img class="icons filter-blue" src="ucs_libraries/share.svg" alt="share_icon">&nbsp;&nbsp;<b>提交</b>');

            // Table
            $("#dataTable").text('UCS音效系统分类表');
            $("#UCSTableSubHeading").text('谷歌在线数据库~ UCS v8.2（如无法使用请检查代理）');
            $("#downloadUCSButtonText").text('点击这里下载离线使用！');
            $("#reenableOnlineUCSButtonText").text('如果您想使用谷歌表数据重新进入“在线模式”，请点击这里.');
            $("#downloadUCSButton").html('<img class="icons filter-green" src="ucs_libraries/data-transfer-download.svg" alt="download_icon">&nbsp;&nbsp;<b>下载列表</b>');
            $("#ucsTableInstrLabel").html('<i>搜索适当的类别，然后单击表格中的一行即可立即填写表格！</i>');
            $("#haveAGreatDay").html('由&nbsp;<a href="https://aaroncendan.me" target="_blank">Aaron Cendan</a>开发，此项目已在GITHUB开源，此界面由<a href="http://wpa.qq.com/pa?p=2:524541577:41" target="_blank">52HZ Studio</a>修改的中文分支');

            // $("#").html('');
            break;
        default:
            break;
    }
}

// ~~~~~~~~~~~~~~~~~~~~
// CHECK FOR OFFLINE UCS DOC
// ~~~~~~~~~~~~~~~~~~~~
function loadOfflineUCSDoc() {
    var xhttp = new XMLHttpRequest();
    xhttp.onreadystatechange = function () {
        if (this.readyState == 4 && this.status == 200) {
            console.log("Found local UCS data file. Entering OFFLINE mode.");
            useOfflineUSCData(this.responseText);
        }
    };
    xhttp.onloadend = function () {
        if (xhttp.status == 404) {
            console.log("No local UCS data file found. Entering ONLINE mode (GSheets data).");
            useGSheetsUSCData();
        }
    }

    // Get language specific offline sheet
    var ucs_lang_file = "";
    if (localStorage.getItem("ucs_language_country") !== null) {
        ucs_lang_file = localStorage.getItem("ucs_language_country");
    } else {
        // Default to English/US
        localStorage.setItem("ucs_language_country", "us");
        ucs_lang_file = "us";
    }
    ucs_lang_file = "ucs_languages/UCS_" + ucs_lang_file + ".txt";

    // Load file
    xhttp.open("GET", ucs_lang_file, true);
    // XML HTTP Cache will try to pull old information if the file is update but keeps the same name.
    // Disable cache controls to get the latest.
    xhttp.setRequestHeader('cache-control', 'no-cache, must-revalidate, post-check=0, pre-check=0');
    xhttp.setRequestHeader('cache-control', 'max-age=0');
    xhttp.setRequestHeader('expires', '0');
    xhttp.setRequestHeader('expires', 'Tue, 01 Jan 1980 1:00:00 GMT');
    xhttp.setRequestHeader('pragma', 'no-cache');
    xhttp.send();
}

// ~~~~~~~~~~~~~~~~~~~~
// CHECK FOR OFFLINE USER PRESETS DOC
// ~~~~~~~~~~~~~~~~~~~~
function loadUserPresets() {
    // Load presets
    if (localStorage.getItem("num-presets") !== null) {
        // Found existing number of presets
        var num_presets = parseInt(localStorage.getItem("num-presets"), 10);
        for (var preset_index = 1; preset_index <= num_presets; preset_index++) {
            if (localStorage.getItem("ucs-preset-" + preset_index) !== null) {
                // Parse JSON
                var presetSettings = JSON.parse(localStorage.getItem("ucs-preset-" + preset_index));

                // Add dropdown element for preset to top of list
                $("#navbarPresetsDropdownOptions").prepend('<a class="dropdown-item" href="#" id="userPreset' + preset_index + '" onClick="loadUserPreset(' + preset_index + ')" style="display: flex; align-items: center;">' + presetSettings.preset + '</a>');

                // Add dropdown element to DELETE preset
                $("#deletePresetSelect").prepend($('<option>', {
                    value: preset_index,
                    text: presetSettings.preset
                }));

                // Load to fields if "Default"
                if (presetSettings.preset.toUpperCase() == "DEFAULT") loadUserPreset(preset_index);
            }
        }
    }
}

// ~~~~~~~~~~~~~~~~~~~~
// SHOW PRESET MODAL
// ~~~~~~~~~~~~~~~~~~~~
function showPresetModal() {
    $('#presetsModal').modal();
    setTimeout(() => { $('#presetName').focus(); }, 500);
}

function showDeletePresetModal() {
    $('#deletePresetsModal').modal();
}

// ~~~~~~~~~~~~~~~~~~~~
// IMPORT/EXPORT PRESETS
// ~~~~~~~~~~~~~~~~~~~~
$("#uploadedPresetFile").change(function () {
    // Get uploaded file
    var uploadedPresetFile = document.getElementById('uploadedPresetFile').files[0];
    if (uploadedPresetFile) {

        var r = new FileReader();
        r.onload = function (e) {
            var presetFileContents = e.target.result;
            /*
            alert( "Got the file.n" 
                +"name: " + uploadedPresetFile.name + "n"
                +"type: " + uploadedPresetFile.type + "n"
                +"size: " + uploadedPresetFile.size + " bytesn"
                + "starts with: " + presetFileContents.substr(1, presetFileContents.indexOf("n"))
            ); 
            console.log(presetFileContents);
            */

            // Validate file
            if (presetFileContents.includes("exported-preset-file")) {
                // Clear existing local storage
                localStorage.clear();

                // Write local storage using preset file
                var presetsJSON = JSON.parse(presetFileContents);
                for (var name in presetsJSON) { localStorage.setItem(name, presetsJSON[name]); }
                console.log(presetsJSON);

                // Reload page
                location.reload();
            } else {
                alert("Invalid settings file! Please only import files that were exported using Settings > Export Data.")
            }

        }
        r.readAsText(uploadedPresetFile);
    }
});

function exportPresetStorage() {
    // Set local storage for preset export
    localStorage.setItem("exported-preset-file", "true");

    // Create text file from array input
    var textFile = null,
        makeTextFile = function (arr) {
            var arrToText = new Blob([JSON.stringify(arr)], { type: 'text/plain' });
            // If we are replacing a previously generated file we need to
            // manually revoke the object URL to avoid memory leaks.
            if (textFile !== null) {
                window.URL.revokeObjectURL(textFile);
            }
            textFile = window.URL.createObjectURL(arrToText);
            return textFile;
        };

    // Create page element for link to file
    var link = document.createElement('a');
    link.setAttribute('download', 'UCS_Data.txt');

    // Write out the whole contents of the localStorage..
    link.href = makeTextFile(localStorage);

    // Spoof user clicking on new download link
    document.body.appendChild(link);
    window.requestAnimationFrame(function () {
        var event = new MouseEvent('click');
        link.dispatchEvent(event);
        document.body.removeChild(link);
    });
}

// ~~~~~~~~~~~~~~~~~~~~
// SAVE CURRENT SETTINGS AS A PRESET
// ~~~~~~~~~~~~~~~~~~~~
function saveThisAsPreset() {
    // Hide modal
    $('#presetsModal').modal('hide');

    //#region Fetch user's settings...            
    var mySettings = {
        presetIndex: preset_index,
        preset: $("#presetName").val(),
        category: $("#userInputCategory").val(),
        subcategory: $("select#userSelectSubCategory option:checked").val(),
        filename: $("#userInputName").val(),
        enumerate: $("#userInputVarNumCheckbox").prop("checked"),
        userCat: $("#userInputUserCat").val(),
        userId: $("#userInputInitials").val(),
        showId: $("#userInputShow").val(),
        userData: $("#userInputData").val(),
        vendorCat: $("#userInputVendCat").val(),
        metaTitle: $("#userInputMetaTitle").val(),
        metaDesc: $("#userInputMetaDesc").val(),
        metaKeys: $("#userInputMetaKeys").val(),
        metaMic: $("#userInputMetaMic").val(),
        metaRecMed: $("#userInputMetaRecMed").val(),
        metaDsgnr: $("#userInputMetaDsgnr").val(),
        metaLib: $("#userInputMetaLib").val(),
        metaURL: $("#userInputMetaURL").val(),
        metaMftr: $("#userInputMetaManufacturer").val(),
        metaNotes: $("#metaNotes").val(),
        metaCoun: $("#countryId").val(),
        metaState: $("#stateId").val(),
        metaCity: $("#cityId").val(),
        metaUserLoc: $("#userLocId").val(),
        metaPersp: $("#userInputMetaPersp").val(),
        metaConfig: $("#userInputMetaConfig").val(),
        metaIntExt: $("#userInputMetaIntExt").val(),
        userItems: $("#userInputItems").val(),
        userArea: $("#userInputArea").val(),
        gbxSuffix: $("#gbxSuffix").val(),
        ASWGcontentType: $("#ASWGcontentType").val(),
        ASWGproject: $("#ASWGproject").val(),
        ASWGoriginatorStudio: $("#ASWGoriginatorStudio").val(),
        ASWGnotes: $("#ASWGnotes").val(),
        ASWGstate: $("#ASWGstate").val(),
        ASWGeditor: $("#ASWGeditor").val(),
        ASWGmixer: $("#ASWGmixer").val(),
        ASWGfxChainName: $("#ASWGfxChainName").val(),
        ASWGchannelConfig: $("#ASWGchannelConfig").val(),
        ASWGambisonicFormat: $("#ASWGambisonicFormat").val(),
        ASWGambisonicChnOrder: $("#ASWGambisonicChnOrder").val(),
        ASWGambisonicNorm: $("#ASWGambisonicNorm").val(),
        ASWGisDesigned: $("#ASWGisDesigned").val(),
        ASWGrecEngineer: $("#ASWGrecEngineer").val(),
        ASWGrecStudio: $("#ASWGrecStudio").val(),
        ASWGimpulseLocation: $("#ASWGimpulseLocation").val(),
        ASWGtext: $("#ASWGtext").val(),
        ASWGefforts: $("#ASWGefforts").val(),
        ASWGeffortType: $("#ASWGeffortType").val(),
        ASWGprojection: $("#ASWGprojection").val(),
        ASWGlanguage: $("#ASWGlanguage").val(),
        ASWGtimingRestriction: $("#ASWGtimingRestriction").val(),
        ASWGcharacterName: $("#ASWGcharacterName").val(),
        ASWGcharacterGender: $("#ASWGcharacterGender").val(),
        ASWGcharacterAge: $("#ASWGcharacterAge").val(),
        ASWGcharacterRole: $("#ASWGcharacterRole").val(),
        ASWGactorName: $("#ASWGactorName").val(),
        ASWGactorGender: $("#ASWGactorGender").val(),
        ASWGdirection: $("#ASWGdirection").val(),
        ASWGdirector: $("#ASWGdirector").val(),
        ASWGfxUsed: $("#ASWGfxUsed").val(),
        ASWGusageRights: $("#ASWGusageRights").val(),
        ASWGisUnion: $("#ASWGisUnion").val(),
        ASWGaccent: $("#ASWGaccent").val(),
        ASWGemotion: $("#ASWGemotion").val(),
        ASWGcomposer: $("#ASWGcomposer").val(),
        ASWGartist: $("#ASWGartist").val(),
        ASWGsongTitle: $("#ASWGsongTitle").val(),
        ASWGgenre: $("#ASWGgenre").val(),
        ASWGsubGenre: $("#ASWGsubGenre").val(),
        ASWGproducer: $("#ASWGproducer").val(),
        ASWGmusicSup: $("#ASWGmusicSup").val(),
        ASWGinstrument: $("#ASWGinstrument").val(),
        ASWGmusicPublisher: $("#ASWGmusicPublisher").val(),
        ASWGrightsOwner: $("#ASWGrightsOwner").val(),
        ASWGintensity: $("#ASWGintensity").val(),
        ASWGorderRef: $("#ASWGorderRef").val(),
        ASWGisSource: $("#ASWGisSource").val(),
        ASWGisLoop: $("#ASWGisLoop").val(),
        ASWGisFinal: $("#ASWGisFinal").val(),
        ASWGisOst: $("#ASWGisOst").val(),
        ASWGisCinematic: $("#ASWGisCinematic").val(),
        ASWGisLicensed: $("#ASWGisLicensed").val(),
        ASWGisDiegetic: $("#ASWGisDiegetic").val(),
        ASWGmusicVersion: $("#ASWGmusicVersion").val(),
        ASWGisrcId: $("#ASWGisrcId").val(),
        ASWGtempo: $("#ASWGtempo").val(),
        ASWGtimeSig: $("#ASWGtimeSig").val(),
        ASWGinKey: $("#ASWGinKey").val(),
        ASWGbillingCode: $("#ASWGbillingCode").val()
    }
    console.log(mySettings);
    //#endregion

    // Get/update number of user presets in local storage
    var preset_index = 0;
    var edit_mode = false;
    if (localStorage.getItem("num-presets") !== null) {
        // Check to see if an existing preset has the same name. Delete if so
        var num_presets = parseInt(localStorage.getItem("num-presets"), 10);
        for (var preset_idx = 1; preset_idx <= num_presets; preset_idx++) {
            if (localStorage.getItem("ucs-preset-" + preset_idx) !== null) {
                var presetSettings = JSON.parse(localStorage.getItem("ucs-preset-" + preset_idx));
                // Found a match
                if (presetSettings.preset === mySettings.preset) {
                    localStorage.removeItem("ucs-preset-" + preset_idx);
                    console.log("Edited preset: " + presetSettings.preset);
                    edit_mode = true;
                    preset_index = preset_idx;
                }
            }
        }
        // Didn't find existing preset with same name
        if (!edit_mode) {
            preset_index = parseInt(localStorage.getItem("num-presets"), 10) + 1;
            localStorage.setItem("num-presets", preset_index.toString());
            console.log("Added preset: " + mySettings.preset);
        }
    } else {
        // No presets stored yet
        localStorage.setItem("num-presets", "1");
        preset_index = 1;
        console.log("Started new preset collection: " + mySettings.preset);
    }

    // Store current preset
    var settingsString = JSON.stringify(mySettings);
    localStorage.setItem("ucs-preset-" + preset_index, settingsString);

    // Update dropdowns
    if (!edit_mode) {
        // Add dropdown element for preset to top of list
        $("#navbarPresetsDropdownOptions").prepend('<a class="dropdown-item" href="#" id="userPreset' + preset_index + '" onClick="loadUserPreset(' + preset_index + ')" style="display: flex; align-items: center;">' + mySettings.preset + '</a>');

        // Add dropdown element to DELETE preset
        $("#deletePresetSelect").prepend($('<option>', {
            value: preset_index,
            text: mySettings.preset
        }));
    }

    // Clear out preset name entry spot. Just kidding! Useful for edits.
    // $("#presetName").val("").trigger('change');
}

// ~~~~~~~~~~~~~~~~~~~~
// LOAD USER PRESETS
// ~~~~~~~~~~~~~~~~~~~~
function loadUserPreset(index) {
    // Close presets dropdown menu, if open
    if ($('#navbarPresetsDropdownOptions').hasClass("show")) $("#navbarPresetsDropdown").dropdown("toggle");

    // Fetch preset
    var presetSettings = JSON.parse(localStorage.getItem("ucs-preset-" + index));

    //#region Set values
    console.log("Loading preset number: " + index);
    if (presetSettings.category && presetSettings.category !== "") $("#userInputCategory").val(presetSettings.category).trigger('change');
    if (presetSettings.subcategory && presetSettings.subcategory !== "Please select a category!") $("#userSelectSubCategory").val(presetSettings.subcategory).trigger('change');
    if (presetSettings.filename && presetSettings.filename !== "") $("#userInputName").val(presetSettings.filename).trigger('change');
    if (presetSettings.userCat && presetSettings.userCat !== "") $("#userInputUserCat").val(presetSettings.userCat).trigger('change');
    if (presetSettings.userId && presetSettings.userId !== "") $("#userInputInitials").val(presetSettings.userId).trigger('change');
    if (presetSettings.showId && presetSettings.showId !== "") $("#userInputShow").val(presetSettings.showId).trigger('change');
    if (presetSettings.userData && presetSettings.userData !== "") $("#userInputData").val(presetSettings.userData).trigger('change');
    if (presetSettings.vendorCat && presetSettings.vendorCat !== "") $("#userInputVendCat").val(presetSettings.vendorCat).trigger('change');
    if (presetSettings.metaTitle && presetSettings.metaTitle !== "") $("#userInputMetaTitle").val(presetSettings.metaTitle).trigger('change');
    if (presetSettings.metaDesc && presetSettings.metaDesc !== "") $("#userInputMetaDesc").val(presetSettings.metaDesc).trigger('change');
    if (presetSettings.metaKeys && presetSettings.metaKeys !== "") $("#userInputMetaKeys").val(presetSettings.metaKeys).trigger('change');
    if (presetSettings.metaMic && presetSettings.metaMic !== "") $("#userInputMetaMic").val(presetSettings.metaMic).trigger('change');
    if (presetSettings.metaRecMed && presetSettings.metaRecMed !== "") $("#userInputMetaRecMed").val(presetSettings.metaRecMed).trigger('change');
    if (presetSettings.metaDsgnr && presetSettings.metaDsgnr !== "") $("#userInputMetaDsgnr").val(presetSettings.metaDsgnr).trigger('change');
    if (presetSettings.metaLib && presetSettings.metaLib !== "") $("#userInputMetaLib").val(presetSettings.metaLib).trigger('change');
    if (presetSettings.metaURL && presetSettings.metaURL !== "") $("#userInputMetaURL").val(presetSettings.metaURL).trigger('change');
    if (presetSettings.metaMftr && presetSettings.metaMftr !== "") $("#userInputMetaManufacturer").val(presetSettings.metaMftr).trigger('change');
    if (presetSettings.metaNotes && presetSettings.metaNotes !== "") $("#metaNotes").val(presetSettings.metaNotes).trigger('change');
    if (presetSettings.metaCoun && presetSettings.metaCoun !== "") setTimeout(() => { $("#countryId").val(presetSettings.metaCoun).trigger('change'); }, 500);
    if (presetSettings.metaState && presetSettings.metaState !== "") setTimeout(() => { $("#stateId").val(presetSettings.metaState).trigger('change'); }, 1000);
    if (presetSettings.metaCity && presetSettings.metaCity !== "") setTimeout(() => { $("#cityId").val(presetSettings.metaCity).trigger('change'); }, 1500);
    if (presetSettings.metaUserLoc && presetSettings.metaUserLoc !== "") $("#userLocId").val(presetSettings.metaUserLoc).trigger('change');
    if (presetSettings.metaPersp && presetSettings.metaPersp !== "-") $("#userInputMetaPersp").val(presetSettings.metaPersp).trigger('change');
    if (presetSettings.metaIntExt && presetSettings.metaIntExt !== "-") $("#userInputMetaIntExt").val(presetSettings.metaIntExt).trigger('change');
    if (presetSettings.userItems && presetSettings.userItems !== "") $("#userInputItems").val(presetSettings.userItems).trigger('change');
    if (presetSettings.gbxSuffix && presetSettings.gbxSuffix !== "") $("#gbxSuffix").val(presetSettings.gbxSuffix).trigger('change');
    if (presetSettings.userArea && presetSettings.userArea !== "") $("#userInputArea").val(presetSettings.userArea).trigger('change');
    $("#userInputVarNumCheckbox").prop("checked", presetSettings.enumerate);

    if (presetSettings.ASWGcontentType && presetSettings.ASWGcontentType !== "-") $("#ASWGcontentType").val(presetSettings.ASWGcontentType).trigger('change');
    if (presetSettings.ASWGproject && presetSettings.ASWGproject !== "") $("#ASWGproject").val(presetSettings.ASWGproject).trigger('change');
    if (presetSettings.ASWGoriginatorStudio && presetSettings.ASWGoriginatorStudio !== "") $("#ASWGoriginatorStudio").val(presetSettings.ASWGoriginatorStudio).trigger('change');
    if (presetSettings.ASWGnotes && presetSettings.ASWGnotes !== "") $("#ASWGnotes").val(presetSettings.ASWGnotes).trigger('change');
    if (presetSettings.ASWGstate && presetSettings.ASWGstate !== "-") $("#ASWGstate").val(presetSettings.ASWGstate).trigger('change');
    if (presetSettings.ASWGeditor && presetSettings.ASWGeditor !== "") $("#ASWGeditor").val(presetSettings.ASWGeditor).trigger('change');
    if (presetSettings.ASWGmixer && presetSettings.ASWGmixer !== "") $("#ASWGmixer").val(presetSettings.ASWGmixer).trigger('change');
    if (presetSettings.ASWGfxChainName && presetSettings.ASWGfxChainName !== "") $("#ASWGfxChainName").val(presetSettings.ASWGfxChainName).trigger('change');
    if (presetSettings.ASWGchannelConfig && presetSettings.ASWGchannelConfig !== "-") $("#ASWGchannelConfig").val(presetSettings.ASWGchannelConfig).trigger('change');
    if (presetSettings.ASWGambisonicFormat && presetSettings.ASWGambisonicFormat !== "") $("#ASWGambisonicFormat").val(presetSettings.ASWGambisonicFormat).trigger('change');
    if (presetSettings.ASWGambisonicChnOrder && presetSettings.ASWGambisonicChnOrder !== "-") $("#ASWGambisonicChnOrder").val(presetSettings.ASWGambisonicChnOrder).trigger('change');
    if (presetSettings.ASWGambisonicNorm && presetSettings.ASWGambisonicNorm !== "-") $("#ASWGambisonicNorm").val(presetSettings.ASWGambisonicNorm).trigger('change');
    if (presetSettings.ASWGisDesigned && presetSettings.ASWGisDesigned !== "-") $("#ASWGisDesigned").val(presetSettings.ASWGisDesigned).trigger('change');
    if (presetSettings.ASWGrecEngineer && presetSettings.ASWGrecEngineer !== "") $("#ASWGrecEngineer").val(presetSettings.ASWGrecEngineer).trigger('change');
    if (presetSettings.ASWGrecStudio && presetSettings.ASWGrecStudio !== "") $("#ASWGrecStudio").val(presetSettings.ASWGrecStudio).trigger('change');
    if (presetSettings.ASWGimpulseLocation && presetSettings.ASWGimpulseLocation !== "") $("#ASWGimpulseLocation").val(presetSettings.ASWGimpulseLocation).trigger('change');
    if (presetSettings.ASWGtext && presetSettings.ASWGtext !== "") $("#ASWGtext").val(presetSettings.ASWGtext).trigger('change');
    if (presetSettings.ASWGefforts && presetSettings.ASWGefforts !== "-") $("#ASWGefforts").val(presetSettings.ASWGefforts).trigger('change');
    if (presetSettings.ASWGeffortType && presetSettings.ASWGeffortType !== "") $("#ASWGeffortType").val(presetSettings.ASWGeffortType).trigger('change');
    if (presetSettings.ASWGprojection && presetSettings.ASWGprojection !== "-") $("#ASWGprojection").val(presetSettings.ASWGprojection).trigger('change');
    if (presetSettings.ASWGlanguage && presetSettings.ASWGlanguage !== "-") $("#ASWGlanguage").val(presetSettings.ASWGlanguage).trigger('change');
    if (presetSettings.ASWGtimingRestriction && presetSettings.ASWGtimingRestriction !== "-") $("#ASWGtimingRestriction").val(presetSettings.ASWGtimingRestriction).trigger('change');
    if (presetSettings.ASWGcharacterName && presetSettings.ASWGcharacterName !== "") $("#ASWGcharacterName").val(presetSettings.ASWGcharacterName).trigger('change');
    if (presetSettings.ASWGcharacterGender && presetSettings.ASWGcharacterGender !== "-") $("#ASWGcharacterGender").val(presetSettings.ASWGcharacterGender).trigger('change');
    if (presetSettings.ASWGcharacterAge && presetSettings.ASWGcharacterAge !== "") $("#ASWGcharacterAge").val(presetSettings.ASWGcharacterAge).trigger('change');
    if (presetSettings.ASWGcharacterRole && presetSettings.ASWGcharacterRole !== "-") $("#ASWGcharacterRole").val(presetSettings.ASWGcharacterRole).trigger('change');
    if (presetSettings.ASWGactorName && presetSettings.ASWGactorName !== "") $("#ASWGactorName").val(presetSettings.ASWGactorName).trigger('change');
    if (presetSettings.ASWGactorGender && presetSettings.ASWGactorGender !== "-") $("#ASWGactorGender").val(presetSettings.ASWGactorGender).trigger('change');
    if (presetSettings.ASWGdirection && presetSettings.ASWGdirection !== "") $("#ASWGdirection").val(presetSettings.ASWGdirection).trigger('change');
    if (presetSettings.ASWGdirector && presetSettings.ASWGdirector !== "") $("#ASWGdirector").val(presetSettings.ASWGdirector).trigger('change');
    if (presetSettings.ASWGfxUsed && presetSettings.ASWGfxUsed !== "") $("#ASWGfxUsed").val(presetSettings.ASWGfxUsed).trigger('change');
    if (presetSettings.ASWGusageRights && presetSettings.ASWGusageRights !== "") $("#ASWGusageRights").val(presetSettings.ASWGusageRights).trigger('change');
    if (presetSettings.ASWGisUnion && presetSettings.ASWGisUnion !== "-") $("#ASWGisUnion").val(presetSettings.ASWGisUnion).trigger('change');
    if (presetSettings.ASWGaccent && presetSettings.ASWGaccent !== "") $("#ASWGaccent").val(presetSettings.ASWGaccent).trigger('change');
    if (presetSettings.ASWGemotion && presetSettings.ASWGemotion !== "") $("#ASWGemotion").val(presetSettings.ASWGemotion).trigger('change');
    if (presetSettings.ASWGcomposer && presetSettings.ASWGcomposer !== "") $("#ASWGcomposer").val(presetSettings.ASWGcomposer).trigger('change');
    if (presetSettings.ASWGartist && presetSettings.ASWGartist !== "") $("#ASWGartist").val(presetSettings.ASWGartist).trigger('change');
    if (presetSettings.ASWGsongTitle && presetSettings.ASWGsongTitle !== "") $("#ASWGsongTitle").val(presetSettings.ASWGsongTitle).trigger('change');
    if (presetSettings.ASWGgenre && presetSettings.ASWGgenre !== "") $("#ASWGgenre").val(presetSettings.ASWGgenre).trigger('change');
    if (presetSettings.ASWGsubGenre && presetSettings.ASWGsubGenre !== "") $("#ASWGsubGenre").val(presetSettings.ASWGsubGenre).trigger('change');
    if (presetSettings.ASWGproducer && presetSettings.ASWGproducer !== "") $("#ASWGproducer").val(presetSettings.ASWGproducer).trigger('change');
    if (presetSettings.ASWGmusicSup && presetSettings.ASWGmusicSup !== "") $("#ASWGmusicSup").val(presetSettings.ASWGmusicSup).trigger('change');
    if (presetSettings.ASWGinstrument && presetSettings.ASWGinstrument !== "") $("#ASWGinstrument").val(presetSettings.ASWGinstrument).trigger('change');
    if (presetSettings.ASWGmusicPublisher && presetSettings.ASWGmusicPublisher !== "") $("#ASWGmusicPublisher").val(presetSettings.ASWGmusicPublisher).trigger('change');
    if (presetSettings.ASWGrightsOwner && presetSettings.ASWGrightsOwner !== "") $("#ASWGrightsOwner").val(presetSettings.ASWGrightsOwner).trigger('change');
    if (presetSettings.ASWGintensity && presetSettings.ASWGintensity !== "") $("#ASWGintensity").val(presetSettings.ASWGintensity).trigger('change');
    if (presetSettings.ASWGorderRef && presetSettings.ASWGorderRef !== "") $("#ASWGorderRef").val(presetSettings.ASWGorderRef).trigger('change');
    if (presetSettings.ASWGisSource && presetSettings.ASWGisSource !== "-") $("#ASWGisSource").val(presetSettings.ASWGisSource).trigger('change');
    if (presetSettings.ASWGisLoop && presetSettings.ASWGisLoop !== "-") $("#ASWGisLoop").val(presetSettings.ASWGisLoop).trigger('change');
    if (presetSettings.ASWGisFinal && presetSettings.ASWGisFinal !== "-") $("#ASWGisFinal").val(presetSettings.ASWGisFinal).trigger('change');
    if (presetSettings.ASWGisOst && presetSettings.ASWGisOst !== "-") $("#ASWGisOst").val(presetSettings.ASWGisOst).trigger('change');
    if (presetSettings.ASWGisCinematic && presetSettings.ASWGisCinematic !== "-") $("#ASWGisCinematic").val(presetSettings.ASWGisCinematic).trigger('change');
    if (presetSettings.ASWGisLicensed && presetSettings.ASWGisLicensed !== "-") $("#ASWGisLicensed").val(presetSettings.ASWGisLicensed).trigger('change');
    if (presetSettings.ASWGisDiegetic && presetSettings.ASWGisDiegetic !== "-") $("#ASWGisDiegetic").val(presetSettings.ASWGisDiegetic).trigger('change');
    if (presetSettings.ASWGmusicVersion && presetSettings.ASWGmusicVersion !== "") $("#ASWGmusicVersion").val(presetSettings.ASWGmusicVersion).trigger('change');
    if (presetSettings.ASWGisrcId && presetSettings.ASWGisrcId !== "") $("#ASWGisrcId").val(presetSettings.ASWGisrcId).trigger('change');
    if (presetSettings.ASWGtempo && presetSettings.ASWGtempo !== "") $("#ASWGtempo").val(presetSettings.ASWGtempo).trigger('change');
    if (presetSettings.ASWGtimeSig && presetSettings.ASWGtimeSig !== "") $("#ASWGtimeSig").val(presetSettings.ASWGtimeSig).trigger('change');
    if (presetSettings.ASWGinKey && presetSettings.ASWGinKey !== "") $("#ASWGinKey").val(presetSettings.ASWGinKey).trigger('change');
    if (presetSettings.ASWGbillingCode && presetSettings.ASWGbillingCode !== "") $("#ASWGbillingCode").val(presetSettings.ASWGbillingCode).trigger('change');
    //#endregion

    // Mic config requires a little bit of extra work due to the ambisonics modal
    if (presetSettings.metaConfig && presetSettings.metaConfig !== "-") {
        if (presetSettings.metaConfig.includes("Ambisonic")) $("#customAmbi").text(presetSettings.metaConfig);
        $("#userInputMetaConfig").val(presetSettings.metaConfig).trigger('change');
    }

    // Set preset edit textbox value
    $("#presetName").val(presetSettings.preset).trigger('change');
}

/**
 * Delete the selected user preset from localStorage and update the UI.
 */
function deleteThisPreset() {
    // Get index of selected option
    var preset_index_to_delete = parseInt($("#deletePresetSelect").val(), 10);

    // Fetch presets
    if (localStorage.getItem("num-presets") !== null) {
        // Found existing number of presets
        var num_presets = parseInt(localStorage.getItem("num-presets"), 10);
        for (var preset_index = 1; preset_index <= num_presets; preset_index++) {
            // Delete the selected preset 
            if (localStorage.getItem("ucs-preset-" + preset_index) !== null && preset_index == preset_index_to_delete) {
                var presetSettings = JSON.parse(localStorage.getItem("ucs-preset-" + preset_index));
                localStorage.removeItem("ucs-preset-" + preset_index_to_delete);
                console.log("Deleted preset: " + presetSettings.preset);

                // Update dropdown elements for preset to top of list
                $("#userPreset" + preset_index).remove();

                // Update dropdown elements for DELETE presets
                $("#deletePresetSelect option[value=" + preset_index_to_delete + "]").remove();
            }
        }
    }
}

/**
 * Save the current settings to the user's history in localStorage and update the dropdown.
 */
function saveThisHistory() {
    // Get user's settings            
    var currentCatID = getCatID($("#userInputCategory").val(), $("select#userSelectSubCategory option:checked").val());
    if ($("#userInputName").val().length > 14) {
        var historyName = month + "/" + day + ": " + currentCatID + "_" + $("#userInputName").val().substring(0, 12) + "..."
    } else {
        var historyName = month + "/" + day + ": " + currentCatID + "_" + $("select#userSelectSubCategory option:checked").val() + " " + $("#userInputName").val();
    }

    //#region Fetch user's settings
    var mySettings = {
        presetIndex: history_index,
        preset: historyName,
        category: $("#userInputCategory").val(),
        subcategory: $("select#userSelectSubCategory option:checked").val(),
        filename: $("#userInputName").val(),
        enumerate: $("#userInputVarNumCheckbox").prop("checked"),
        userCat: $("#userInputUserCat").val(),
        userId: $("#userInputInitials").val(),
        showId: $("#userInputShow").val(),
        userData: $("#userInputData").val(),
        vendorCat: $("#userInputVendCat").val(),
        metaTitle: $("#userInputMetaTitle").val(),
        metaDesc: $("#userInputMetaDesc").val(),
        metaKeys: $("#userInputMetaKeys").val(),
        metaMic: $("#userInputMetaMic").val(),
        metaRecMed: $("#userInputMetaRecMed").val(),
        metaDsgnr: $("#userInputMetaDsgnr").val(),
        metaLib: $("#userInputMetaLib").val(),
        metaURL: $("#userInputMetaURL").val(),
        metaMftr: $("#userInputMetaManufacturer").val(),
        metaNotes: $("#metaNotes").val(),
        metaCoun: $("#countryId").val(),
        metaState: $("#stateId").val(),
        metaCity: $("#cityId").val(),
        metaUserLoc: $("#userLocId").val(),
        metaPersp: $("#userInputMetaPersp").val(),
        metaConfig: $("#userInputMetaConfig").val(),
        metaIntExt: $("#userInputMetaIntExt").val(),
        userItems: $("#userInputItems").val(),
        userArea: $("#userInputArea").val(),
        gbxSuffix: $("#gbxSuffix").val(),
        ASWGcontentType: $("#ASWGcontentType").val(),
        ASWGproject: $("#ASWGproject").val(),
        ASWGoriginatorStudio: $("#ASWGoriginatorStudio").val(),
        ASWGnotes: $("#ASWGnotes").val(),
        ASWGstate: $("#ASWGstate").val(),
        ASWGeditor: $("#ASWGeditor").val(),
        ASWGmixer: $("#ASWGmixer").val(),
        ASWGfxChainName: $("#ASWGfxChainName").val(),
        ASWGchannelConfig: $("#ASWGchannelConfig").val(),
        ASWGambisonicFormat: $("#ASWGambisonicFormat").val(),
        ASWGambisonicChnOrder: $("#ASWGambisonicChnOrder").val(),
        ASWGambisonicNorm: $("#ASWGambisonicNorm").val(),
        ASWGisDesigned: $("#ASWGisDesigned").val(),
        ASWGrecEngineer: $("#ASWGrecEngineer").val(),
        ASWGrecStudio: $("#ASWGrecStudio").val(),
        ASWGimpulseLocation: $("#ASWGimpulseLocation").val(),
        ASWGtext: $("#ASWGtext").val(),
        ASWGefforts: $("#ASWGefforts").val(),
        ASWGeffortType: $("#ASWGeffortType").val(),
        ASWGprojection: $("#ASWGprojection").val(),
        ASWGlanguage: $("#ASWGlanguage").val(),
        ASWGtimingRestriction: $("#ASWGtimingRestriction").val(),
        ASWGcharacterName: $("#ASWGcharacterName").val(),
        ASWGcharacterGender: $("#ASWGcharacterGender").val(),
        ASWGcharacterAge: $("#ASWGcharacterAge").val(),
        ASWGcharacterRole: $("#ASWGcharacterRole").val(),
        ASWGactorName: $("#ASWGactorName").val(),
        ASWGactorGender: $("#ASWGactorGender").val(),
        ASWGdirection: $("#ASWGdirection").val(),
        ASWGdirector: $("#ASWGdirector").val(),
        ASWGfxUsed: $("#ASWGfxUsed").val(),
        ASWGusageRights: $("#ASWGusageRights").val(),
        ASWGisUnion: $("#ASWGisUnion").val(),
        ASWGaccent: $("#ASWGaccent").val(),
        ASWGemotion: $("#ASWGemotion").val(),
        ASWGcomposer: $("#ASWGcomposer").val(),
        ASWGartist: $("#ASWGartist").val(),
        ASWGsongTitle: $("#ASWGsongTitle").val(),
        ASWGgenre: $("#ASWGgenre").val(),
        ASWGsubGenre: $("#ASWGsubGenre").val(),
        ASWGproducer: $("#ASWGproducer").val(),
        ASWGmusicSup: $("#ASWGmusicSup").val(),
        ASWGinstrument: $("#ASWGinstrument").val(),
        ASWGmusicPublisher: $("#ASWGmusicPublisher").val(),
        ASWGrightsOwner: $("#ASWGrightsOwner").val(),
        ASWGintensity: $("#ASWGintensity").val(),
        ASWGorderRef: $("#ASWGorderRef").val(),
        ASWGisSource: $("#ASWGisSource").val(),
        ASWGisLoop: $("#ASWGisLoop").val(),
        ASWGisFinal: $("#ASWGisFinal").val(),
        ASWGisOst: $("#ASWGisOst").val(),
        ASWGisCinematic: $("#ASWGisCinematic").val(),
        ASWGisLicensed: $("#ASWGisLicensed").val(),
        ASWGisDiegetic: $("#ASWGisDiegetic").val(),
        ASWGmusicVersion: $("#ASWGmusicVersion").val(),
        ASWGisrcId: $("#ASWGisrcId").val(),
        ASWGtempo: $("#ASWGtempo").val(),
        ASWGtimeSig: $("#ASWGtimeSig").val(),
        ASWGinKey: $("#ASWGinKey").val(),
        ASWGbillingCode: $("#ASWGbillingCode").val()
    }
    console.log(mySettings);
    //#endregion

    // Get/update number of user history in local storage
    var history_index = 0;
    var edit_mode = false;
    if (localStorage.getItem("num-history") !== null) {

        // Increment index
        var num_history = parseInt(localStorage.getItem("num-history"), 10);
        history_index = parseInt(localStorage.getItem("num-history"), 10) + 1;
        localStorage.setItem("num-history", history_index.toString());

    } else {
        // No history stored yet
        localStorage.setItem("num-history", "1");
        history_index = 1;
    }

    // Store current history
    var settingsString = JSON.stringify(mySettings);
    localStorage.setItem("ucs-history-" + history_index, settingsString);

    // Add dropdown element for this history to top of list
    $("#navbarHistoryDropdownOptions").prepend('<a class="dropdown-item" href="#" id="userHistory' + history_index + '" onClick="loadThisHistory(' + history_index + ')" style="display: flex; align-items: center;">' + mySettings.preset + '</a>');

    // Delete old history
    deleteOldHistory();
}

/**
 * Load a specific history entry by index and populate the UI fields.
 * @param {number} index The index of the history entry to load.
 */
function loadThisHistory(index) {
    // Close presets dropdown menu, if open
    if ($('#navbarHistoryDropdownOptions').hasClass("show")) $("#navbarHistoryDropdown").dropdown("toggle");

    // Fetch preset
    var historySettings = JSON.parse(localStorage.getItem("ucs-history-" + index));

    //#region Set values
    console.log("Loading history number: " + index);
    if (historySettings.category && historySettings.category !== "") $("#userInputCategory").val(historySettings.category).trigger('change');
    if (historySettings.subcategory && historySettings.subcategory !== "Please select a category!") $("#userSelectSubCategory").val(historySettings.subcategory).trigger('change');
    if (historySettings.filename && historySettings.filename !== "") $("#userInputName").val(historySettings.filename).trigger('change');
    if (historySettings.userCat && historySettings.userCat !== "") $("#userInputUserCat").val(historySettings.userCat).trigger('change');
    if (historySettings.userId && historySettings.userId !== "") $("#userInputInitials").val(historySettings.userId).trigger('change');
    if (historySettings.showId && historySettings.showId !== "") $("#userInputShow").val(historySettings.showId).trigger('change');
    if (historySettings.userData && historySettings.userData !== "") $("#userInputData").val(historySettings.userData).trigger('change');
    if (historySettings.vendorCat && historySettings.vendorCat !== "") $("#userInputVendCat").val(historySettings.vendorCat).trigger('change');
    if (historySettings.metaTitle && historySettings.metaTitle !== "") $("#userInputMetaTitle").val(historySettings.metaTitle).trigger('change');
    if (historySettings.metaDesc && historySettings.metaDesc !== "") $("#userInputMetaDesc").val(historySettings.metaDesc).trigger('change');
    if (historySettings.metaKeys && historySettings.metaKeys !== "") $("#userInputMetaKeys").val(historySettings.metaKeys).trigger('change');
    if (historySettings.metaMic && historySettings.metaMic !== "") $("#userInputMetaMic").val(historySettings.metaMic).trigger('change');
    if (historySettings.metaRecMed && historySettings.metaRecMed !== "") $("#userInputMetaRecMed").val(historySettings.metaRecMed).trigger('change');
    if (historySettings.metaDsgnr && historySettings.metaDsgnr !== "") $("#userInputMetaDsgnr").val(historySettings.metaDsgnr).trigger('change');
    if (historySettings.metaLib && historySettings.metaLib !== "") $("#userInputMetaLib").val(historySettings.metaLib).trigger('change');
    if (historySettings.metaURL && historySettings.metaURL !== "") $("#userInputMetaURL").val(historySettings.metaURL).trigger('change');
    if (historySettings.metaMftr && historySettings.metaMftr !== "") $("#userInputMetaManufacturer").val(historySettings.metaMftr).trigger('change');
    if (historySettings.metaNotes && historySettings.metaNotes !== "") $("#metaNotes").val(historySettings.metaNotes).trigger('change');
    if (historySettings.metaCoun && historySettings.metaCoun !== "") setTimeout(() => { $("#countryId").val(historySettings.metaCoun).trigger('change'); }, 500);
    if (historySettings.metaState && historySettings.metaState !== "") setTimeout(() => { $("#stateId").val(historySettings.metaState).trigger('change'); }, 1000);
    if (historySettings.metaCity && historySettings.metaCity !== "") setTimeout(() => { $("#cityId").val(historySettings.metaCity).trigger('change'); }, 1500);
    if (historySettings.metaUserLoc && historySettings.metaUserLoc !== "") $("#userLocId").val(historySettings.metaUserLoc).trigger('change');
    if (historySettings.metaPersp && historySettings.metaPersp !== "-") $("#userInputMetaPersp").val(historySettings.metaPersp).trigger('change');
    if (historySettings.metaIntExt && historySettings.metaIntExt !== "-") $("#userInputMetaIntExt").val(historySettings.metaIntExt).trigger('change');
    if (historySettings.userItems && historySettings.userItems !== "") $("#userInputItems").val(historySettings.userItems).trigger('change');
    if (historySettings.userArea && historySettings.userArea !== "") $("#userInputArea").val(historySettings.userArea).trigger('change');
    if (historySettings.gbxSuffix && historySettings.gbxSuffix !== "") $("#gbxSuffix").val(historySettings.gbxSuffix).trigger('change');
    $("#userInputVarNumCheckbox").prop("checked", historySettings.enumerate);

    if (historySettings.ASWGcontentType && historySettings.ASWGcontentType !== "-") $("#ASWGcontentType").val(historySettings.ASWGcontentType).trigger('change');
    if (historySettings.ASWGproject && historySettings.ASWGproject !== "") $("#ASWGproject").val(historySettings.ASWGproject).trigger('change');
    if (historySettings.ASWGoriginatorStudio && historySettings.ASWGoriginatorStudio !== "") $("#ASWGoriginatorStudio").val(historySettings.ASWGoriginatorStudio).trigger('change');
    if (historySettings.ASWGnotes && historySettings.ASWGnotes !== "") $("#ASWGnotes").val(historySettings.ASWGnotes).trigger('change');
    if (historySettings.ASWGstate && historySettings.ASWGstate !== "-") $("#ASWGstate").val(historySettings.ASWGstate).trigger('change');
    if (historySettings.ASWGeditor && historySettings.ASWGeditor !== "") $("#ASWGeditor").val(historySettings.ASWGeditor).trigger('change');
    if (historySettings.ASWGmixer && historySettings.ASWGmixer !== "") $("#ASWGmixer").val(historySettings.ASWGmixer).trigger('change');
    if (historySettings.ASWGfxChainName && historySettings.ASWGfxChainName !== "") $("#ASWGfxChainName").val(historySettings.ASWGfxChainName).trigger('change');
    if (historySettings.ASWGchannelConfig && historySettings.ASWGchannelConfig !== "-") $("#ASWGchannelConfig").val(historySettings.ASWGchannelConfig).trigger('change');
    if (historySettings.ASWGambisonicFormat && historySettings.ASWGambisonicFormat !== "") $("#ASWGambisonicFormat").val(historySettings.ASWGambisonicFormat).trigger('change');
    if (historySettings.ASWGambisonicChnOrder && historySettings.ASWGambisonicChnOrder !== "-") $("#ASWGambisonicChnOrder").val(historySettings.ASWGambisonicChnOrder).trigger('change');
    if (historySettings.ASWGambisonicNorm && historySettings.ASWGambisonicNorm !== "-") $("#ASWGambisonicNorm").val(historySettings.ASWGambisonicNorm).trigger('change');
    if (historySettings.ASWGisDesigned && historySettings.ASWGisDesigned !== "-") $("#ASWGisDesigned").val(historySettings.ASWGisDesigned).trigger('change');
    if (historySettings.ASWGrecEngineer && historySettings.ASWGrecEngineer !== "") $("#ASWGrecEngineer").val(historySettings.ASWGrecEngineer).trigger('change');
    if (historySettings.ASWGrecStudio && historySettings.ASWGrecStudio !== "") $("#ASWGrecStudio").val(historySettings.ASWGrecStudio).trigger('change');
    if (historySettings.ASWGimpulseLocation && historySettings.ASWGimpulseLocation !== "") $("#ASWGimpulseLocation").val(historySettings.ASWGimpulseLocation).trigger('change');
    if (historySettings.ASWGtext && historySettings.ASWGtext !== "") $("#ASWGtext").val(historySettings.ASWGtext).trigger('change');
    if (historySettings.ASWGefforts && historySettings.ASWGefforts !== "-") $("#ASWGefforts").val(historySettings.ASWGefforts).trigger('change');
    if (historySettings.ASWGeffortType && historySettings.ASWGeffortType !== "") $("#ASWGeffortType").val(historySettings.ASWGeffortType).trigger('change');
    if (historySettings.ASWGprojection && historySettings.ASWGprojection !== "-") $("#ASWGprojection").val(historySettings.ASWGprojection).trigger('change');
    if (historySettings.ASWGlanguage && historySettings.ASWGlanguage !== "-") $("#ASWGlanguage").val(historySettings.ASWGlanguage).trigger('change');
    if (historySettings.ASWGtimingRestriction && historySettings.ASWGtimingRestriction !== "-") $("#ASWGtimingRestriction").val(historySettings.ASWGtimingRestriction).trigger('change');
    if (historySettings.ASWGcharacterName && historySettings.ASWGcharacterName !== "") $("#ASWGcharacterName").val(historySettings.ASWGcharacterName).trigger('change');
    if (historySettings.ASWGcharacterGender && historySettings.ASWGcharacterGender !== "-") $("#ASWGcharacterGender").val(historySettings.ASWGcharacterGender).trigger('change');
    if (historySettings.ASWGcharacterAge && historySettings.ASWGcharacterAge !== "") $("#ASWGcharacterAge").val(historySettings.ASWGcharacterAge).trigger('change');
    if (historySettings.ASWGcharacterRole && historySettings.ASWGcharacterRole !== "-") $("#ASWGcharacterRole").val(historySettings.ASWGcharacterRole).trigger('change');
    if (historySettings.ASWGactorName && historySettings.ASWGactorName !== "") $("#ASWGactorName").val(historySettings.ASWGactorName).trigger('change');
    if (historySettings.ASWGactorGender && historySettings.ASWGactorGender !== "-") $("#ASWGactorGender").val(historySettings.ASWGactorGender).trigger('change');
    if (historySettings.ASWGdirection && historySettings.ASWGdirection !== "") $("#ASWGdirection").val(historySettings.ASWGdirection).trigger('change');
    if (historySettings.ASWGdirector && historySettings.ASWGdirector !== "") $("#ASWGdirector").val(historySettings.ASWGdirector).trigger('change');
    if (historySettings.ASWGfxUsed && historySettings.ASWGfxUsed !== "") $("#ASWGfxUsed").val(historySettings.ASWGfxUsed).trigger('change');
    if (historySettings.ASWGusageRights && historySettings.ASWGusageRights !== "") $("#ASWGusageRights").val(historySettings.ASWGusageRights).trigger('change');
    if (historySettings.ASWGisUnion && historySettings.ASWGisUnion !== "-") $("#ASWGisUnion").val(historySettings.ASWGisUnion).trigger('change');
    if (historySettings.ASWGaccent && historySettings.ASWGaccent !== "") $("#ASWGaccent").val(historySettings.ASWGaccent).trigger('change');
    if (historySettings.ASWGemotion && historySettings.ASWGemotion !== "") $("#ASWGemotion").val(historySettings.ASWGemotion).trigger('change');
    if (historySettings.ASWGcomposer && historySettings.ASWGcomposer !== "") $("#ASWGcomposer").val(historySettings.ASWGcomposer).trigger('change');
    if (historySettings.ASWGartist && historySettings.ASWGartist !== "") $("#ASWGartist").val(historySettings.ASWGartist).trigger('change');
    if (historySettings.ASWGsongTitle && historySettings.ASWGsongTitle !== "") $("#ASWGsongTitle").val(historySettings.ASWGsongTitle).trigger('change');
    if (historySettings.ASWGgenre && historySettings.ASWGgenre !== "") $("#ASWGgenre").val(historySettings.ASWGgenre).trigger('change');
    if (historySettings.ASWGsubGenre && historySettings.ASWGsubGenre !== "") $("#ASWGsubGenre").val(historySettings.ASWGsubGenre).trigger('change');
    if (historySettings.ASWGproducer && historySettings.ASWGproducer !== "") $("#ASWGproducer").val(historySettings.ASWGproducer).trigger('change');
    if (historySettings.ASWGmusicSup && historySettings.ASWGmusicSup !== "") $("#ASWGmusicSup").val(historySettings.ASWGmusicSup).trigger('change');
    if (historySettings.ASWGinstrument && historySettings.ASWGinstrument !== "") $("#ASWGinstrument").val(historySettings.ASWGinstrument).trigger('change');
    if (historySettings.ASWGmusicPublisher && historySettings.ASWGmusicPublisher !== "") $("#ASWGmusicPublisher").val(historySettings.ASWGmusicPublisher).trigger('change');
    if (historySettings.ASWGrightsOwner && historySettings.ASWGrightsOwner !== "") $("#ASWGrightsOwner").val(historySettings.ASWGrightsOwner).trigger('change');
    if (historySettings.ASWGintensity && historySettings.ASWGintensity !== "") $("#ASWGintensity").val(historySettings.ASWGintensity).trigger('change');
    if (historySettings.ASWGorderRef && historySettings.ASWGorderRef !== "") $("#ASWGorderRef").val(historySettings.ASWGorderRef).trigger('change');
    if (historySettings.ASWGisSource && historySettings.ASWGisSource !== "-") $("#ASWGisSource").val(historySettings.ASWGisSource).trigger('change');
    if (historySettings.ASWGisLoop && historySettings.ASWGisLoop !== "-") $("#ASWGisLoop").val(historySettings.ASWGisLoop).trigger('change');
    if (historySettings.ASWGisFinal && historySettings.ASWGisFinal !== "-") $("#ASWGisFinal").val(historySettings.ASWGisFinal).trigger('change');
    if (historySettings.ASWGisOst && historySettings.ASWGisOst !== "-") $("#ASWGisOst").val(historySettings.ASWGisOst).trigger('change');
    if (historySettings.ASWGisCinematic && historySettings.ASWGisCinematic !== "-") $("#ASWGisCinematic").val(historySettings.ASWGisCinematic).trigger('change');
    if (historySettings.ASWGisLicensed && historySettings.ASWGisLicensed !== "-") $("#ASWGisLicensed").val(historySettings.ASWGisLicensed).trigger('change');
    if (historySettings.ASWGisDiegetic && historySettings.ASWGisDiegetic !== "-") $("#ASWGisDiegetic").val(historySettings.ASWGisDiegetic).trigger('change');
    if (historySettings.ASWGmusicVersion && historySettings.ASWGmusicVersion !== "") $("#ASWGmusicVersion").val(historySettings.ASWGmusicVersion).trigger('change');
    if (historySettings.ASWGisrcId && historySettings.ASWGisrcId !== "") $("#ASWGisrcId").val(historySettings.ASWGisrcId).trigger('change');
    if (historySettings.ASWGtempo && historySettings.ASWGtempo !== "") $("#ASWGtempo").val(historySettings.ASWGtempo).trigger('change');
    if (historySettings.ASWGtimeSig && historySettings.ASWGtimeSig !== "") $("#ASWGtimeSig").val(historySettings.ASWGtimeSig).trigger('change');
    if (historySettings.ASWGinKey && historySettings.ASWGinKey !== "") $("#ASWGinKey").val(historySettings.ASWGinKey).trigger('change');
    if (historySettings.ASWGbillingCode && historySettings.ASWGbillingCode !== "") $("#ASWGbillingCode").val(historySettings.ASWGbillingCode).trigger('change');
    //#endregion

    // Mic config requires a little bit of extra work due to the ambisonics modal
    if (historySettings.metaConfig && historySettings.metaConfig !== "-") {
        if (historySettings.metaConfig.includes("Ambisonic")) $("#customAmbi").text(historySettings.metaConfig);
        $("#userInputMetaConfig").val(historySettings.metaConfig).trigger('change');
    }
}

/**
 * Delete old history entries if the number exceeds the maximum allowed slots.
 */
function deleteOldHistory() {
    // Fetch presets
    if (localStorage.getItem("num-history") !== null) {
        // Count the actual number of saved history items
        var num_history = parseInt(localStorage.getItem("num-history"), 10);
        var actual_num = 0;
        for (var history_index = 1; history_index <= num_history; history_index++) {
            if (localStorage.getItem("ucs-history-" + history_index) !== null) {
                actual_num = actual_num + 1;
            }
        }

        // Delete the lowest numbers up to the max history slots
        var max_history_slots = 10
        for (var history_index = 1; history_index <= num_history; history_index++) {
            if (localStorage.getItem("ucs-history-" + history_index) !== null) {
                if (actual_num > max_history_slots) {
                    localStorage.removeItem("ucs-history-" + history_index);
                    $("#userHistory" + history_index).remove();
                    actual_num = actual_num - 1;
                }
            }
        }
    }
}

/**
 * Load all user history entries and fill out the dropdown menu.
 */
function loadUserHistory() {
    // Load presets
    if (localStorage.getItem("num-history") !== null) {
        // Found existing number of presets
        var num_history = parseInt(localStorage.getItem("num-history"), 10);
        for (var history_index = 1; history_index <= num_history; history_index++) {
            if (localStorage.getItem("ucs-history-" + history_index) !== null) {
                // Parse JSON
                var historySettings = JSON.parse(localStorage.getItem("ucs-history-" + history_index));

                // Add dropdown element for history to top of list
                $("#navbarHistoryDropdownOptions").prepend('<a class="dropdown-item" href="#" id="userHistory' + history_index + '" onClick="loadThisHistory(' + history_index + ')" style="display: flex; align-items: center;">' + historySettings.preset + '</a>');
            }
        }
    }
}

/**
 * GBX Mod: Update the UI for GBX naming convention.
 * Format: GBX [UCS Cat] [UCS Sub Cat] [Brief Description based on Meta Tag incl Source + Source Descriptor] [Mic] SRC
 * Example: GBX FOLY CLOTH Canvas Large Snap Whoosh Cloth Fight Explo 416 SRC.wav
 */
function GBXMod() {
    // Update Title
    $("#navbarTitle").text("UCS Tool - GBX Mod");
    $("#navbarLogo").attr("src", "ucs_libraries/gbx_logo.png");

    // // Brief Description = File Name
    // $("#fileNameLabelText").text("GBX - Brief Description*");
    // $("#userInputName").attr("placeholder", "Based on Meta Tag including source and source descriptor");

    // // Hide variation numberin
    // $("#userInputVarNumCheckbox").prop("checked",false);
    // $("#varNumberingDiv").hide();

    // // GBX Microphone = User Data/Notes
    $("#userInputDataLabel").text("GBX - Microphone*");
    $("#userInputData").attr("placeholder", "416, 8040, CO100K, synth");
    $("#userInputDataHelp").text("If source was synthesis, use 'synth'.");
    // Sync Microphone field with metadata mic
    $("#userInputData").on("input", function () { $("#userInputMetaMic").val(this.value); });
    $("#userInputMetaMic").on("input", function () { $("#userInputData").val(this.value); });

    // GBX Suffix (Show Hidden Dropdown)
    $("#gbxSuffixGroup").show();

    // // Hide & Remove: User Category, Creator ID, Source ID
    $("#userInputInitials").removeAttr('required');
    $("#initialsGroup").hide();
    //$("#userCategoryGroup").hide();
    // $("#showGroup").hide();
}

/**
 * Use offline UCS data if available and populate the DataTable and autocomplete arrays.
 * @param {string} offlineTableData The offline UCS data as a JSON string.
 */
function useOfflineUSCData(offlineTableData) {
    // Display appropriate HTML elements
    $("#UCSTableSubHeading").text("UCS Data Offline Mode ~ UCS v8.2");
    //$("#reenableOnlineUCSButtonText").show();
    //$("#onlineUCSButton").show();

    // Build full table from offline info
    jsonFullTable = JSON.parse(offlineTableData);

    // Loop through table data
    for (let [key, value] of Object.entries(jsonFullTable)) {
        var jsonCategory = value[0];
        var jsonSubcategory = value[1];
        var jsonCatID = value[2];
        var jsonShortID = value[3];
        var jsonExplanation = value[4];
        var jsonSynonym = value[5];

        // Build category & subcategory array for dynamic subcategories
        if (!jsonCategorySubcategoryArr.hasOwnProperty(jsonCategory)) {
            jsonCategorySubcategoryArr[jsonCategory] = jsonSubcategory;
        } else {
            jsonCategorySubcategoryArr[jsonCategory] = jsonCategorySubcategoryArr[jsonCategory] + ", " + jsonSubcategory;
        }

        // Build CatID array for Reaper
        if (!jsonCatIDArr.hasOwnProperty(jsonCatID)) {
            jsonCatIDArr[jsonCatID] = jsonCategory + ", " + jsonSubcategory;
        } else {
            console.log("There is a duplicate CatID: " + jsonCatID + "\n" + "Using first occurrence: " + jsonCatIDArr[jsonCatID]);
        }

        // Build autocomplete arrays
        if (!jsonCategoryAutofill.includes(jsonCategory) && jsonCategory != "Category") {
            jsonCategoryAutofill.push(jsonCategory);
        }
        if (!jsonSubcategoryAutofill.includes(jsonSubcategory) && jsonSubcategory != "SubCategory" && jsonSubcategory != "-") {
            jsonSubcategoryAutofill.push(jsonSubcategory);
        }
    }

    // Initialize data table
    $('#UCRTDataTable').DataTable({
        "paging": true,
        "info": false,
        "lengthChange": false,
        "pageLength": 50,
        data: jsonFullTable,
        columns: [
            { title: "Category" },
            { title: "Subcategory" },
            { title: "CatID" },
            { title: "ShortID" },
            { title: "Explanations" },
            { title: "Synonyms" }
        ],
        "dom": '<"dtSearch"f>rt<"dtPages"lp><"clear">'
    });

    $('.dataTables_filter input[type="search"]').css(
        { 'min-width': '500px', 'display': 'inline-block' }
    );
}

/**
 * Use Google Sheets UCS data if offline data is not available, populate DataTable and autocomplete arrays.
 */
function useGSheetsUSCData() {
    // Display appropriate HTML elements
    $("#downloadUCSButton").show();
    $("#downloadUCSButtonText").show();

    // Parse JSON from Google Sheet
    var ucs_gsheet = "";

    if (localStorage.getItem("ucs_language") !== null) {
        console.log("Language preference found in local storage.")
        ucs_gsheet = localStorage.getItem("ucs_language");
    } else {
        console.log("No language preference set. Default: English.");
        localStorage.setItem("ucs_language", ucs_gsheet_en);
        localStorage.setItem("ucs_language_country", "us");
        ucs_gsheet = ucs_gsheet_en;
    }

    $.getJSON(ucs_gsheet, function (data) {
        var entry = data.feed.entry;

        // Get UCS data version number
        var UCSVersionNumber = entry[0].content.$t;
        $("#UCSTableSubHeading").text("Google Sheets Data/Online Mode ~ UCS " + UCSVersionNumber);

        // Loop through the JSON, starting on the second row (skip headers)
        // For this process to work, there CANNOT be any blank cells
        for (var i = 6; i < entry.length - 6; i += 6) {
            // entry[i].content.$t retrieves the content of each cell
            var jsonCategory = entry[i].content.$t;
            var jsonSubcategory = entry[i + 1].content.$t;
            var jsonCatID = entry[i + 2].content.$t;
            var jsonShortID = entry[i + 3].content.$t;
            var jsonExplanation = entry[i + 4].content.$t;
            var jsonSynonym = entry[i + 5].content.$t;

            // Build full table for DataTable
            jsonFullTable.push([jsonCategory, jsonSubcategory, jsonCatID, jsonShortID, jsonExplanation, jsonSynonym]);

            // Build category & subcategory array for dynamic subcategories
            if (!jsonCategorySubcategoryArr.hasOwnProperty(jsonCategory)) {
                jsonCategorySubcategoryArr[jsonCategory] = jsonSubcategory;
            } else {
                jsonCategorySubcategoryArr[jsonCategory] = jsonCategorySubcategoryArr[jsonCategory] + ", " + jsonSubcategory;
            }

            // Build CatID array for Reaper
            if (!jsonCatIDArr.hasOwnProperty(jsonCatID)) {
                jsonCatIDArr[jsonCatID] = jsonCategory + ", " + jsonSubcategory;
            } else {
                console.log("There is a duplicate CatID: " + jsonCatID + "\n" + "Using first occurrence: " + jsonCatIDArr[jsonCatID]);
            }

            // Build autocomplete arrays
            if (!jsonCategoryAutofill.includes(jsonCategory) && jsonCategory != "Category") {
                jsonCategoryAutofill.push(jsonCategory);
            }
            if (!jsonSubcategoryAutofill.includes(jsonSubcategory) && jsonSubcategory != "SubCategory" && jsonSubcategory != "-") {
                jsonSubcategoryAutofill.push(jsonSubcategory);
            }
        }

        // Initialize data table
        $('#UCRTDataTable').DataTable({
            "paging": true,
            "info": false,
            "lengthChange": false,
            "pageLength": 50,
            data: jsonFullTable,
            columns: [
                { title: "Category" },
                { title: "Subcategory" },
                { title: "CatID" },
                { title: "ShortID" },
                { title: "Explanations" },
                { title: "Synonyms" }
            ],
            "dom": '<"dtSearch"f>rt<"dtPages"lp><"clear">'
        });

        $('.dataTables_filter input[type="search"]').css(
            { 'width': '100%', 'box-sizing': 'border-box', 'max-width': '500px', 'display': 'inline-block' }
        );
    })
}

/**
 * Set a REAPER project extstate value using the web interface.
 * Can accept an HTML element ID as the first argument, or a value and extstate field name.
 * @param {string} field The HTML element ID or value.
 * @param {string} [extName] The extstate field name (optional).
 */
function setProjExtState(field, extName = "") {
    var htmlEle = document.getElementById(field);
    if (htmlEle) {
        var val = htmlEle.value;
        wwr_req("SET/PROJEXTSTATE/UCS_WebInterface/" + field + "/" + val);
    } else {
        var val = field;
        wwr_req("SET/PROJEXTSTATE/UCS_WebInterface/" + extName + "/" + val);
    }
}

/**
 * Find the CatID from the selected category and subcategory.
 * @param {string} selectedCat The selected category.
 * @param {string} selectedSubcat The selected subcategory.
 * @return {string} The CatID or 'CATID_INVALID' if not found.
 */
function getCatID(selectedCat, selectedSubcat) {
    var arrVal = selectedCat + ", " + selectedSubcat;
    if (Object.keys(jsonCatIDArr).find(key => jsonCatIDArr[key] === arrVal)) {
        var arrCatID = Object.keys(jsonCatIDArr).find(key => jsonCatIDArr[key] === arrVal);
        console.log("Found CatID: " + arrCatID);
        return arrCatID;
    } else {
        //alert("No valid CatID found." + "\n" + "\n" + "Please check your Category & Subcategory selections!");
        $("#userInputCategoryError").show();
        window.scrollTo(0, 0);
        var invalid = "CATID_INVALID";
        return invalid;
    }
}

/**
 * Clean up the user's file name input and split it into name and number.
 * Uses RegEx to ensure name conforms to UCS standard.
 * @param {string} name The input name string.
 * @return {Array} [cleanName, number] The cleaned name and number as strings.
 */
function getNameAndNumber(name) {
    var fxFormattingSetting = $("#fxFormattingSetting").val();
    var cleanName = (fxFormattingSetting.includes("Enable")) ? stringCleaning(name) : name.replace(/_/g, " ");
    var matches = cleanName.match(/\d+$/);
    if (matches) {
        // If user included a number at the end of the name...
        var number = String(parseInt(matches[0], 10));
        var noNum = cleanName.replace(/\d+$/, "");
        var noSpace = stringCleaning(noNum);
        console.log("Name: " + noSpace + " | Number: " + number);
        return [noSpace, number];
    } else {
        // Start at 1 otherwise
        var number = "1";
        console.log("Name: " + cleanName + " | Number: " + number);
        return [cleanName, number];
    }
}

/**
 * Clean up user input fields using RegEx.
 * @param {string} inString The input string to clean.
 * @return {string} The cleaned string.
 */
function stringCleaning(inString) {
    var noIllegalChars = inString.replace(/[\"\'\~\`\@\=\&\*\/\\\:\<\>\?\|\%\#\!\+\[\]\{\}]/g, "");    // Removes illegal characters
    var noLeadingWhitespace = noIllegalChars.replace(/^\s+/, "");                          // Removes whitespace at start of string
    var noTrailingWhitespace = noLeadingWhitespace.replace(/\s+$/, "");                    // Removes whitespace at end of string
    var noUnderscores = noTrailingWhitespace.replace(/_/g, " ");                           // Replaces underscores with spaces
    var noDoubleSpaces = noUnderscores.replace(/\s\s+/g, " ");                             // Removes double spaces, tabs, or multiple spaces in the middle of a string
    return noDoubleSpaces;
}

/**
 * Download a "UCS.txt" blob file from the UCS array.
 * Spoofs a download link on the page for the created file, clicks it, then removes the link.
 */
function downloadBlobFile() {
    // Open Reaper resource path
    wwr_req(encodeURIComponent(REApath));

    // Create text file from array input
    var textFile = null,
        makeTextFile = function (arr) {
            var arrToText = new Blob([JSON.stringify(arr)], { type: 'text/plain' });
            // If we are replacing a previously generated file we need to
            // manually revoke the object URL to avoid memory leaks.
            if (textFile !== null) {
                window.URL.revokeObjectURL(textFile);
            }
            textFile = window.URL.createObjectURL(arrToText);
            return textFile;
        };

    // Create page element for link to file
    var link = document.createElement('a');
    link.setAttribute('download', 'UCS.txt');
    link.href = makeTextFile(jsonFullTable);

    // Spoof user clicking on new download link
    document.body.appendChild(link);
    window.requestAnimationFrame(function () {
        var event = new MouseEvent('click');
        link.dispatchEvent(event);
        document.body.removeChild(link);
    });
}