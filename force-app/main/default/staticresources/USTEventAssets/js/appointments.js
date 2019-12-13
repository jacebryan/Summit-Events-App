document.addEventListener("DOMContentLoaded", () => {
    let apptFormatted = '';
    let chooser =  document.querySelector("#chooser");
    for (i = 0; i < appointments.length; i++) {
        apptGroup = appointments[i];
        grp = document.createElement("div");
        if (apptGroup.typeId) {
            grp.setAttribute("id", apptGroup.typeId);
        } else {
            grp.setAttribute("id", 'generalPlaceholder');
        }
        grp.setAttribute("data-choosable", apptGroup.choosable);
        grp.classList.add('apptGroup');
        grp.innerHTML = '<h5 class="apptGroupTitle">' + apptGroup.title + '</h5>';
        grp.innerHTML += '<p class="apptGroupDesc">' + apptGroup.description + '</p>';
        chooser.append(grp);

        for (ii = 0; ii < apptGroup.appointments.length; ii++) {
            appt = apptGroup.appointments[ii];
            apptItem= document.createElement("div");
            apptItem.setAttribute("id", appt.typeId);
            apptItem.setAttribute("data-groupTypeId",  apptGroup.Id);
            apptItem.setAttribute("data-apptTypeId",  appt.typeId);
            apptItem.setAttribute("data-apptId",  appt.chosenId);
            apptItem.classList.add("appointment");
            apptItem.innerHTML = '<p class="appointmentTitle"><a href="javascript:;" class="optionToggler"><span>' + appt.title + '</span></span><i class="fa fa-chevron-down" aria-hidden="true"></i></a></p>';
            apptItemDesc = document.createElement("div");
            apptItemDesc.classList.add("apptmentDetail");
            apptItemDesc.innerHTML = '<p class="appointmentDesc">' + appt.description + '</p>';
            apptItemDesc.innerHTML += '<a href="javascript:;" class="appointmentAdd"><span><i class="fa fa-plus" aria-hidden="true"></i> Add appointment</span></a>';
            apptItem.append(apptItemDesc);
            grp.append(apptItem);

        }
        apptFormatted += '</div>';
    }

    document.querySelector("#chooser").append(grp);

    var apptTitles = document.getElementsByClassName("appointmentTitle");
    for (var i = 0; i < apptTitles.length; i++) {
        var clickedElem = apptTitles[i];
        clickedElem.addEventListener('click', function(evt) {
            showAppointmentDetail(this)
        }, false);
    }

    function showAppointmentDetail(appt) {
        //alert(appt.innerHTML);
        var toggleThis = appt.closest("div");
        var children = toggleThis.childNodes, number_of_children = children.length;
        for (var i=0; i<number_of_children; i++) {
            if (children[i].classList.contains("apptmentDetail")) {
                //alert(children[i].innerHTML);
                toggle(children[i], 'block');
            }
        }
    }


    // $(".appointmentTitle a").on("click", function () {
    //     if ($(this).find("i").hasClass("fa-chevron-down")) {
    //         $(this).find("i").removeClass("fa-chevron-down").addClass("fa-chevron-up");
    //     } else {
    //         $(this).find("i").removeClass("fa-chevron-up").addClass("fa-chevron-down");
    //     }
    //     $(this).closest(".appointment").find(".apptmentDetail").slideToggle("fast");
    // });

    $("#chooser .appointmentAdd").on("click", function () {
        //find apptGroup, does it exist in the choosen pile add if it does not
        //Add appointment to appointment group
        alert('click');
    })

});


function toggle(el, value) {
    var display = (window.getComputedStyle ? getComputedStyle(el, null) : el.currentStyle).display;
    if (display == 'none') el.style.display = value;
    else el.style.display = 'none';
}

function hide(el) {
    el.style.display = 'none';
}

function show(el, value) {
    el.style.display = value;
}

function toggle(el, value) {
    var display = (window.getComputedStyle ? getComputedStyle(el, null) : el.currentStyle).display;
    if (display == 'none') el.style.display = value;
    else el.style.display = 'none';
}


// matches polyfill
this.Element && function(ElementPrototype) {
    ElementPrototype.matches = ElementPrototype.matches ||
        ElementPrototype.matchesSelector ||
        ElementPrototype.webkitMatchesSelector ||
        ElementPrototype.msMatchesSelector ||
        function(selector) {
            var node = this, nodes = (node.parentNode || node.document).querySelectorAll(selector), i = -1;
            while (nodes[++i] && nodes[i] != node);
            return !!nodes[i];
        }
}(Element.prototype);

// closest polyfill
this.Element && function(ElementPrototype) {
    ElementPrototype.closest = ElementPrototype.closest ||
        function(selector) {
            var el = this;
            while (el.matches && !el.matches(selector)) el = el.parentNode;
            return el.matches ? el : null;
        }
}(Element.prototype);