function initializeDonations(donations) {
    function donationForId(id) {
        var matching = $.grep(donations, function (donation) { return donation.id == id; });
        return matching[0];
    }

    function donationIdForDiv(div) {
        var divId = div.attr('id');
        var match = divId.match(/donation-(\d+)/);
        if (!match) return undefined;
        return match[1];
    }

    function donationDivForElement(e) {
        return $(e).closest('div.donation');
    }

    function donationForDiv(div) {
        return donationForId(donationIdForDiv(div));
    }

    function divForDonation(donation) {
        var divId = 'donation-' + donation.id;
        return $('#' + divId);
    }

    function addToPaying(donation) {
        donation.paying = true;
        var card = divForDonation(donation);
        card.find('.checkmark').fadeIn(200);
        updateTotal();
    }

    function removeFromPaying(donation) {
        donation.paying = false;
        var card = divForDonation(donation);
        card.find('.checkmark').fadeOut(200);
        updateTotal();
    }

    function removeFromList(donation) {
        var index = donations.indexOf(donation);
        if (index >= 0) {
            donations.splice(index, 1);
        }
        updateTotal();
    }

    function payingDonations() {
        return $.grep(donations, function (donation) { return donation.paying; });
    }

    function eligibleDonations() {
        return $.grep(donations, function (donation) { return donation['can_send_money?']; });
    }

    function donationTotal(list) {
        var sum = 0;
        $.each(list, function (i, donation) {
            sum += donation.price_cents;
        });
        return sum/100;
    }

    function formatMoney(amount) {
        var fmt = "";
        if (amount % 1 === 0) {
            fmt = amount.toString();
        } else {
            fmt = amount.toFixed(2);
        }
        return "$" + fmt;
    }

    function updateTotal() {
        var paying = payingDonations();
        var eligible = eligibleDonations();
        var total = 0;
        var add = null;
        var remove = null;

        if (paying.length > 0) {
            total = donationTotal(paying);
            $('#donations-total').text(formatMoney(total));
            $('#payment-button').removeClass("pay-for-all");
            $('#payment-button').addClass("pay-for-selected");
        } else if (eligible.length > 0) {
            total = donationTotal(eligible);
            $('#donations-total').text(formatMoney(total));
            $('#payment-button').removeClass("pay-for-selected");
            $('#payment-button').addClass("pay-for-all");
        } else {
            $('#payment-button-row:visible').fadeAndSlideOut();
        }
    }

    $('.donation .button.donation-send').click(function () {
        var card = donationDivForElement(this);
        var donation = donationForDiv(card);
        removeFromPaying(donation);
        card.find('.buttons').fadeOut();
        card.find('.shipping').fadeAndSlideIn();
    });

    $('.donation .close_link').click(function (event) {
        event.preventDefault();
        var card = donationDivForElement(this);
        card.find('.buttons').fadeIn();
        card.find('.shipping').fadeAndSlideOut();
    });

    $('.donation .button.donation-pay').click(function () {
        var card = donationDivForElement(this);
        var donation = donationForDiv(card);
        if (donation.paying) {
            removeFromPaying(donation);
        } else {
            addToPaying(donation);
        }
    });

    $('.donation').handleAjax(function () {
        if ($('div.donation:visible').size() === 1) {
            $('.any-donations').animate({height: 'toggle', opacity: 'toggle'}, {duration: 600});
            $('.no-donations').animate({height: 'toggle', opacity: 'toggle'}, {duration: 600});
        } else {
            var card = donationDivForElement(this);
            var donation = donationForDiv(card);
            removeFromList(donation);
            $(this).animate({height: 'toggle', opacity: 'toggle'}, {duration: 600});
        }
    });

    $('#payment-button').click(function () {
        var paying = payingDonations();
        if (paying.length === 0) paying = eligibleDonations();

        var form = $('#payment-form');
        $.each(paying, function (i, donation) {
            var input = $('<input>').attr({type: 'hidden', name: 'donation_ids[]', value: donation.id});
            form.append(input);
        });

        form.submit();
    });

    $('.donate-explanation-link').click(function () {
        $('.donate-explanation').fadeAndSlide();
    });

    updateTotal();
}
