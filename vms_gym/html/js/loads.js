const formatDate = (timestamp) => {
    const date = new Date((Number(timestamp) * 1000));
    let hour = date.getHours();
    let minute = date.getMinutes();
    let day = date.getDate();
    let month = date.getMonth() + 1;
    let year = date.getFullYear();
    if (hour < 10) hour = '0' + hour
    if (minute < 10) minute = '0' + minute
    if (day < 10) day = '0' + day
    if (month < 10) month = '0' + month

    return { date: day + '.' + month + '.' + year, time: hour + ':' + minute }
};

const PurchaseMenu = {
    LoadAvailable: (useMemberships, membershipsList, myMembership, useProteins, proteinsList) => {


        $('.purchase-menu .header .proteins').hide();
        $('.purchase-menu .header .memberships').hide();
        
        if (useProteins) {
            let proteinsData = '';
            for (const [k, v] of Object.entries(proteinsList)) {
                proteinsData += `
                    <div>
                        ${v.icon ? `
                            <div class="image">
                                <img src="./images/${v.icon}">
                            </div>
                        ` : ''}
                        <div class="informations">
                            <div class="label">${v.label}</div>
                            <div class="description">${v.description}</div>
                        </div>
                        ${v.price && v.price >= 1 && `
                            <div class="purchase-btn" onclick="buyProtein('${v.name}')">${translation.purchase_menu.proteins.buy_for} ${translation.currency}${!useCityHallIncludedTaxes && v.totalAmount || v.price}</div>
                        ` || `
                            <div class="purchase-btn" onclick="buyProtein('${v.name}')">${translation.purchase_menu.proteins.take}</div>
                        `}
                    </div>
                `
            }
            $('.purchase-menu .header .proteins').addClass('active');
            $('.purchase-menu .header .proteins').show();

            $('.purchase-menu .proteins-menu').html(proteinsData).show();
        }
        
        if (useMemberships) {
            let membershipsData = ``;

            if (myMembership) {
                let {date, time} = formatDate(Number(myMembership))
                membershipsData += `
                    <div class="current-membership has-membership">
                        <i class="fa-solid fa-circle-check"></i>
                        <span>${(translation.purchase_menu.memberships.your_membership).format(date, time)}</span>
                    </div>
                `
            } else {
                membershipsData += `
                    <div class="current-membership">
                        <i class="fa-solid fa-clock"></i>
                        <span>${translation.purchase_menu.memberships.non_membership}</span>
                    </div>
                `
            }

            membershipsData += `<div class="list">`
            for (const [k, v] of Object.entries(membershipsList)) {
                const icon = (v.hours && !v.days) ? 'fa-clock'
                    : (v.days === 1 && !v.hours) ? 'fa-sun'
                    : (v.days <= 7) ? 'fa-calendar-week'
                    : 'fa-calendar-days';
                membershipsData += `
                    <div>
                        <div class="tier-icon"><i class="fa-solid ${icon}"></i></div>
                        <div class="time">
                            <p>
                                ${translation.purchase_menu.memberships.membership_for}
                                ${v.days ? `${v.days} ${v.days === 1 ? translation.day : translation.days}` : ''}
                                ${v.hours ? `${v.hours} ${v.hours === 1 ? translation.hour : translation.hours}` : ''}
                            </p>
                        </div>
                        <div class="purchase-btn" onclick="buyMembership(${v.days}, ${v.hours})">
                            <p>${translation.purchase_menu.memberships.buy_for} ${translation.currency}${!useCityHallIncludedTaxes && v.totalAmount || v.price}</p>
                        </div>
                    </div>
                `
            }
            membershipsData += `</div>`

            $('.purchase-menu .header .proteins').removeClass('active');
            $('.purchase-menu .header .memberships').addClass('active');
            $('.purchase-menu .header .memberships').show();

            $('.purchase-menu .proteins-menu').hide();

            $('.purchase-menu .memberships-menu').html(membershipsData).show();
        }

        $('.purchase-menu').css('display', 'flex');
        $('.purchase-menu > div').fadeIn(120);
    }
}


loadAnnoucements = (announcements) => {
    let announcementsData = ''
    for (const [k, v] of Object.entries(announcements)) {
        if (v) {
            announcementsData = announcementsData + `
                <div>
                    <div class="user">
                        <div class="avatar"><i class="fa-solid fa-user"></i></div>
                        <div class="name">${v.name}</div>
                    </div>
                    <div class="message">${v.message}</div>
                </div>
            `
        }
    }
    return announcementsData;
}

loadMemberships = (memberships) => {
    let membershipsData = ''
    for (const [k, v] of Object.entries(memberships)) {
        membershipsData += `
            <div>
                <div class="time">
                    <p>
                        ${translation.management_menu.memberships.membership_for}
                        ${v.days ? `${v.days} ${translation.days}` : ''}
                        ${v.hours ? `${v.hours} ${translation.hours}` : ''}
                    </p>
                </div>
                <div class="sell-btn" onclick="sellMembership(${v.days}, ${v.hours})">
                    <p>${translation.management_menu.memberships.sell_for} ${translation.currency}${!useCityHallIncludedTaxes && v.totalAmount || v.price}</p>
                </div>
            </div>
        `
    }
    return membershipsData;
}

loadProteins = (proteins) => {
    let proteinsData = ''
    for (const [k, v] of Object.entries(proteins)) {
        proteinsData += `
            <div>
                <div class="info">
                    ${v.icon ? `
                        <div class="image">
                            <img src="./images/${v.icon}">
                        </div>
                    ` : ''}
                    <div class="label">${v.label}</div>
                    ${v.price && v.price >= 1 && `<div class="price" id="${v.name}-price">${translation.currency}${!useCityHallIncludedTaxes && v.totalAmount || v.price}</div>` || ''}
                </div>
                <div class="description">${v.description}</div>
                <div class="actions">
                    <input type="number" oninput="proteinOnChange(this, '${v.name}', ${!useCityHallIncludedTaxes && v.totalAmount || v.price})" id="${v.name}-count" value="1">
                    <div class="sell-btn" onclick="sellProtein('${v.name}', '${v.label}')">${translation.management_menu.proteins.sell}</div>
                </div>
            </div>
        `
    }
    return proteinsData;
}

loadEmployees = (employees) => {
    let employeesData = ''
    for (const [k, v] of Object.entries(employees)) {
        employeesData = employeesData + `
            <tr>
                <td class="table-first">${v.name}</td>
                <td>${v.job ? v.job.grade_label : v.grade.name}</td>
                <td class="table-last"><div onclick="manageEmployee('${v.name}', '${v.identifier || v.empSource}')">${translation.management_menu.management.menu_employees_btn_manage}</div></td>
            </tr>
        `
    }
    return employeesData;
}

let balanceAlreadyRemoved = false
loadBalance = (balance) => {
    if (useBuildInBalance) {
        $('.management-menu div[data-type="boss-management"] div[data-type="balance"] .title').html(`${translation.currency} ${number.format(balance)}`);
    } else {
        if (!balanceAlreadyRemoved && removeBalanceFromMenu) {
            var element = document.querySelector('.management-menu div[data-type="boss-management"] div[data-type="balance"]');
            if (element) element.remove();

            $('.management-menu div[data-type="boss-management"] .header-buttons').css({'grid-template-columns': 'auto'})
            $('.management-menu div[data-type="boss-management"] div[data-type="employees-count"]').css({'width': '100%'})

            
            balanceAlreadyRemoved = true;
        }
        if (!removeBalanceFromMenu) {
            $('.management-menu div[data-type="boss-management"] div[data-type="balance"] .title').html(`${translation.currency} ${number.format(balance)}`);

        }
    }
}