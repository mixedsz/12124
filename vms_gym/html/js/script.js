let translation = [];

var number = Intl.NumberFormat('en-US', {minimumFractionDigits: 0});

String.prototype.format = function() {
    var formatted = this;
    for (var i = 0; i < arguments.length; i++) {
        var regexp = new RegExp('\\{'+i+'\\}', 'gi');
        formatted = formatted.replace(regexp, arguments[i]);
    }
    return formatted;
};

var statisticsmenu = {}

let useBuildInBalance = true;
let removeBalanceFromMenu = false;

var isEmployee = false;
var isManager = false;
var isBoss = false;
var cityhallGrades = false;

let useCityHall = false;
let useCityHallResumes = false;
let useCityHallTaxes = false;
let useCityHallIncludedTaxes = false;
let taxBusinessAllowMakeDelayedDeclarations = false;
let taxBusinessPercentagePerMonthForDelay = false;

let currentMenu = null;
let selectedOption = null;


window.addEventListener("load", function () {
	if (!localStorage.getItem("notify-status")) {
		localStorage.setItem(`notify-status`, 0);
	}

    $.post(`https://${GetParentResourceName()}/loaded`);
});

document.onkeyup = function(data) {
	if (data.which == 27) {
		if (currentMenu == 'purchase_menu') {
			$.post(`https://${GetParentResourceName()}/closePurchaseMenu`);
		} else if (currentMenu == 'statistics') {
			$.post(`https://${GetParentResourceName()}/closeStatisticsMenu`);
		} else if (currentMenu != 'receipt') {
            $.post(`https://${GetParentResourceName()}/closeManagementMenu`);
            currentMenu = null
		}
	}
};

window.addEventListener('message', function(event) {
  	var item = event.data
  	switch (item.action) {
		case 'loaded':
            let lang = item.lang;

            useBuildInBalance = item.useBuildInBalance;
            removeBalanceFromMenu = item.removeBalanceFromMenu;
            
            useCityHall = item.useCityHall;
            useCityHallResumes = item.useCityHallResumes;
            useCityHallTaxes = item.useCityHallTaxes;
            useCityHallIncludedTaxes = item.useCityHallIncludedTaxes;

            taxBusinessAllowMakeDelayedDeclarations = item.taxBusinessAllowMakeDelayedDeclarations;
            taxBusinessPercentagePerMonthForDelay = item.taxBusinessPercentagePerMonthForDelay;

            if (item.uiColor) {
                const { r, g, b } = item.uiColor;
                const mid = (x, d) => Math.max(0, Math.round(x * d));
                const root = document.documentElement.style;
                root.setProperty('--ui-r', r);
                root.setProperty('--ui-g', g);
                root.setProperty('--ui-b', b);
                root.setProperty('--ui-r-mid',  mid(r, 0.8));
                root.setProperty('--ui-g-mid',  mid(g, 0.77));
                root.setProperty('--ui-b-mid',  mid(b, 0.8));
                root.setProperty('--ui-r-dark', mid(r, 0.47));
                root.setProperty('--ui-g-dark', mid(g, 0.35));
                root.setProperty('--ui-b-dark', mid(b, 0.62));
                root.setProperty('--main-color',       `rgb(${r},${g},${b})`);
                root.setProperty('--main-color-hover',  `rgb(${mid(r,0.8)},${mid(g,0.77)},${mid(b,0.8)})`);
                root.setProperty('--main-color-active', `rgb(${mid(r,0.47)},${mid(g,0.35)},${mid(b,0.62)})`);
                root.setProperty('--scrollbar-color',       `rgb(${r},${g},${b})`);
                root.setProperty('--scrollbar-color-hover', `rgb(${mid(r,0.8)},${mid(g,0.77)},${mid(b,0.8)})`);
            }

			$.post(`https://${GetParentResourceName()}/notifyStatus`, JSON.stringify({status: localStorage.getItem("notify-status")}));
			$(`.statistics-menu #notification-status div[data-value=${localStorage.getItem("notify-status")}]`).addClass('status-button-active')
			
			if (item.statisticsmenu) {
				statisticsmenu = item.statisticsmenu
				for (const [key, value] of Object.entries(item.statisticsmenu)) {
					if (value) $(`#${key}`).show();
				}	
			}

			$.ajax({
                url: '../config/translation.json',
                type: 'GET',
                dataType: 'json',
                success: function (code, statut) {
                    if (!code[lang]) {
                        translation = code["EN"];
                        console.warn(`^7Selected language ^1"${lang}"^7 not found, changed to ^2"EN"^7, configure your language in translation.json.`);
                    } else {
                        translation = code[lang];
                    }
                    
					$('.stamina-text').html(translation.help_menu.stamina_text);
					$('.key-x').html(translation.help_menu.x);
					$('.key-space').html(translation.help_menu.space);

					$('.header > span').html(translation.statistics_menu.header);
					$('#strenght .stat-name').text(translation.statistics_menu.strenght);
					$('#condition .stat-name').text(translation.statistics_menu.condition);
					$('#shooting .stat-name').text(translation.statistics_menu.shooting);
					$('#driving .stat-name').text(translation.statistics_menu.driving);
					$('#flying .stat-name').text(translation.statistics_menu.flying);
					$('#notification-status .status-name').text(translation.statistics_menu.notify_status);
					$('#notification-status .enabled-status-name').text(translation.statistics_menu.notify_enabled_status);
					$('#notification-status .disabled-status-name').text(translation.statistics_menu.notify_disabled_status);

					$('.purchase-menu .header .memberships').text(translation.purchase_menu.memberships_btn);
					$('.purchase-menu .header .proteins').text(translation.purchase_menu.proteins_btn);
					
					
                    $('.receipt > .receipt-texts > .header-label').text(translation.receipt.header)
                    $('.receipt > .receipt-texts .item').text(translation.receipt.item)
                    $('.receipt > .receipt-texts .amount').text(translation.receipt.amount)
                    $('.receipt > .receipt-texts .total > div:first-child').text(translation.receipt.total)
                    $('.receipt > .receipt-texts .pay_cash').text(translation.receipt.pay_cash)
                    $('.receipt > .receipt-texts .pay_bank').text(translation.receipt.pay_bank)
                    $('.receipt > .receipt-texts .cancel').text(translation.receipt.cancel)
                    

					// Management Translation:
                    $('.management-menu .side-bar div[data-href="main"] .title').text(translation.management_menu.sidebar.main_title);
                    $('.management-menu .side-bar div[data-href="main"] .description').text(translation.management_menu.sidebar.main_description);

                    $('.management-menu .side-bar div[data-href="employees"] .title').text(translation.management_menu.sidebar.employees_title);
                    $('.management-menu .side-bar div[data-href="employees"] .description').text(translation.management_menu.sidebar.employees_description);
                    
                    $('.management-menu .side-bar div[data-href="memberships"] .title').text(translation.management_menu.sidebar.memberships_title);
                    $('.management-menu .side-bar div[data-href="memberships"] .description').text(translation.management_menu.sidebar.memberships_description);
                    
                    $('.management-menu .side-bar div[data-href="proteins"] .title').text(translation.management_menu.sidebar.proteins_title);
                    $('.management-menu .side-bar div[data-href="proteins"] .description').text(translation.management_menu.sidebar.proteins_description);
                    
                    $('.management-menu .side-bar div[data-href="boss-management"] .title').text(translation.management_menu.sidebar.boss_management_title);
                    $('.management-menu .side-bar div[data-href="boss-management"] .description').text(translation.management_menu.sidebar.boss_management_description);
                    
                    // Main:
                    $('.management-menu div[data-type="main"] div[data-type="announcements"] .header').text(translation.management_menu.main.menu_announcements_header);
                    $('.management-menu div[data-type="main"] div[data-type="announcements"] .title').text(translation.management_menu.main.menu_announcements_title);
                    $('.management-menu div[data-type="main"] div[data-type="total-earned"] .header').text(translation.management_menu.main.menu_total_earned_header);
                    $('.management-menu div[data-type="main"] div[data-type="best-sellers"] .header').text(translation.management_menu.main.menu_best_sellers_header);

                    // Employees:
                    $('.management-menu div[data-type="employees"] .header').text(translation.management_menu.employees.menu_employees_header);
                    $('.management-menu div[data-type="employees"] .title').text(translation.management_menu.employees.menu_employees_title);
                    $('.management-menu div[data-type="employees"] .btn[data-option="get_closest_players"] p').text(translation.management_menu.employees.menu_employees_btn);
                    $('.management-menu div[data-type="employees"] .employees-list #employees-table thead tr th span#employee').text(translation.management_menu.employees.table_employee);
                    $('.management-menu div[data-type="employees"] .employees-list #employees-table thead tr th span#grade').text(translation.management_menu.employees.table_grade);
                    $('.management-menu div[data-type="employees"] .employees-list #employees-table thead tr th span#option').text(translation.management_menu.employees.table_option);

                    // Memberships:
                    $('.management-menu div[data-type="memberships"] .header').text(translation.management_menu.memberships.menu_memberships_header);
                    $('.management-menu div[data-type="memberships"] .title').text(translation.management_menu.memberships.menu_memberships_title);
                    
                    // Proteins:
                    $('.management-menu div[data-type="proteins"] .header').text(translation.management_menu.proteins.menu_proteins_header);
                    $('.management-menu div[data-type="proteins"] .title').text(translation.management_menu.proteins.menu_proteins_title);

                    // Management:
                    $('.management-menu div[data-type="boss-management"] div[data-type="balance"] .header').text(translation.management_menu.management.menu_balance_header);
                    $('.management-menu div[data-type="boss-management"] div[data-type="balance"] div[data-option="withdraw"] p').text(translation.management_menu.management.menu_balance_btn_withdraw);
                    $('.management-menu div[data-type="boss-management"] div[data-type="balance"] div[data-option="deposit"] p').text(translation.management_menu.management.menu_balance_btn_deposit);
                    $('.management-menu div[data-type="boss-management"] div[data-type="employees-count"] .header').text(translation.management_menu.management.menu_employees_header);
                    $('.management-menu div[data-type="boss-management"] div[data-option="employees"] p').text(translation.management_menu.management.menu_employees_btn_manage);
                    $('.management-menu div[data-type="boss-management"] div[data-type="send-announcement"] .header').text(translation.management_menu.management.menu_announcement_header);
                    $('.management-menu div[data-type="boss-management"] div[data-type="send-announcement"] .title').text(translation.management_menu.management.menu_announcement_title);
                    $('.management-menu div[data-type="boss-management"] div[data-type="send-announcement"] .btn p').text(translation.management_menu.management.menu_announcement_btn_send);

                    if (useCityHall) {
                        let { CityHall_SideBars, CityHall_Menus } = window.mySharedFunction();
                        
                        $('.management-menu > .menu > .side-bar').append(`
                            ${useCityHallResumes ? (CityHall_SideBars.resumes).format(translation.management_menu.sidebar.resumes_title, translation.management_menu.sidebar.resumes_description) : ''}
                            ${useCityHallTaxes ? (CityHall_SideBars.taxes).format(translation.management_menu.sidebar.taxes_title, translation.management_menu.sidebar.taxes_description) : ''}
                        `)
        
                        $('.management-menu > .menu > .main').append(`
                            ${useCityHallResumes ? (CityHall_Menus.resumes).format(
                                translation.management_menu.resumes.list_header,
                                translation.management_menu.resumes.list_title,
        
                                translation.management_menu.resumes.table_citizen,
                                translation.management_menu.resumes.table_date,
                                translation.management_menu.resumes.table_option,
        
                                translation.management_menu.resumes.manage_header,
                                translation.management_menu.resumes.manage_title,
        
                                translation.management_menu.resumes.manage_description,
                                translation.management_menu.resumes.manage_toggle_btn,
                            ) : ''}
    
                            ${useCityHallTaxes ? (CityHall_Menus.taxes).format(
                                translation.management_menu.taxes.taxes_header,
                                translation.management_menu.taxes.taxes_title
                            ) : ''}
                        `)
                    }
                }
            })
			
			break;
		case 'openHelpKeys':
			$('.helpInfo').fadeIn(225)
			$('.helpButtons').fadeIn(225)
			break;
		case 'closeHelpKeys':
			$('.helpInfo').fadeOut(225)
			$('.helpButtons').fadeOut(225)
			break;
		case 'update':
			if ((item.stamina).toString()) {
				var currentStamina = item.stamina >= 0.0 && item.stamina || 0.0
				$('.stamina-value').css('width', `${currentStamina}%`)
			}
			break;
		case 'openStatisticsMenu':
			$(this).removeClass('hide');
			$('.statistics-menu').fadeIn(150);
			currentMenu = 'statistics';

			if (statisticsmenu.strenght && item.stats.strenght != undefined && (item.stats.strenght).toString()) {
				$('#strenght .stat-percent').text(`${(item.stats.strenght).toFixed(1)}%`);
				$('#strenght .stat-bar-value').css('width', `${item.stats.strenght}%`);
			}
			if (statisticsmenu.condition && item.stats.condition != undefined && (item.stats.condition).toString()) {
				$('#condition .stat-percent').text(`${(item.stats.condition).toFixed(1)}%`);
				$('#condition .stat-bar-value').css('width', `${item.stats.condition}%`);
			}
			if (statisticsmenu.shooting && item.stats.shooting != undefined && (item.stats.shooting).toString()) {
				$('#shooting .stat-percent').text(`${(item.stats.shooting).toFixed(1)}%`);
				$('#shooting .stat-bar-value').css('width', `${item.stats.shooting}%`);
			}
			if (statisticsmenu.driving && item.stats.driving != undefined && (item.stats.driving).toString()) {
				$('#driving .stat-percent').text(`${(item.stats.driving).toFixed(1)}%`);
				$('#driving .stat-bar-value').css('width', `${item.stats.driving}%`);
			}
			if (statisticsmenu.flying && item.stats.flying != undefined && (item.stats.flying).toString()) {
				$('#flying .stat-percent').text(`${(item.stats.flying).toFixed(1)}%`);
				$('#flying .stat-bar-value').css('width', `${item.stats.flying}%`);
			}
			break;
		case 'updateStatisticsMenu':
			if (statisticsmenu.strenght && item.stats.strenght != undefined && (item.stats.strenght).toString()) {
				$('#strenght .stat-percent').text(`${(item.stats.strenght).toFixed(1)}%`);
				$('#strenght .stat-bar-value').css('width', `${item.stats.strenght}%`);
			}
			if (statisticsmenu.condition && item.stats.condition != undefined && (item.stats.condition).toString()) {
				$('#condition .stat-percent').text(`${(item.stats.condition).toFixed(1)}%`);
				$('#condition .stat-bar-value').css('width', `${item.stats.condition}%`);
			}
			if (statisticsmenu.shooting && item.stats.shooting != undefined && (item.stats.shooting).toString()) {
				$('#shooting .stat-percent').text(`${(item.stats.shooting).toFixed(1)}%`);
				$('#shooting .stat-bar-value').css('width', `${item.stats.shooting}%`);
			}
			if (statisticsmenu.driving && item.stats.driving != undefined && (item.stats.driving).toString()) {
				$('#driving .stat-percent').text(`${(item.stats.driving).toFixed(1)}%`);
				$('#driving .stat-bar-value').css('width', `${item.stats.driving}%`);
			}
			if (statisticsmenu.flying && item.stats.flying != undefined && (item.stats.flying).toString()) {
				$('#flying .stat-percent').text(`${(item.stats.flying).toFixed(1)}%`);
				$('#flying .stat-bar-value').css('width', `${item.stats.flying}%`);
			}
			break;
		case 'closeStatisticsMenu':
			currentMenu = null;
			$('.statistics-menu').addClass('hide');
			$('.statistics-menu').fadeOut(150, function() {
				$(this).removeClass('hide');
			});
			break;
		case 'openPurchaseMenu':
			if (item.useMemberships || item.useProteins) {
				currentMenu = 'purchase_menu';

				PurchaseMenu.LoadAvailable(
					item.useMemberships,
					item.membershipsList,
					item.myMembership,
					item.useProteins,
					item.proteinsList
				);		

			}
			break;
		case 'updatePurchaseMenu':
			if (item.type && item.type == 'membership') {
				if (item.myMembership) {
					let {date, time} = formatDate(Number(item.myMembership))
					$('.purchase-menu .memberships-menu .current-membership').html((translation.purchase_menu.memberships.your_membership).format(date, time))
				} else {
					$('.purchase-menu .memberships-menu .current-membership').html(translation.purchase_menu.memberships.non_membership)
				}
			}
			break;
		case 'closePurchaseMenu':
			$('.purchase-menu').fadeOut(120);
			$('.purchase-menu > div').fadeOut(120);
			break;
		case 'openManagementMenu':
            isEmployee = item.isEmployee;
            isManager = item.isManager;
            isBoss = item.isBoss;
            cityhallGrades = item.cityhallGrades;

            storeCfg = item.storeCfg;
            storeData = item.storeData;
            employees = item.employees;

            $('.management-menu > .menu > .select-player, .management-menu > .menu > .select-player > div').hide();

            // Main Menu - loader:
            $('.management-menu .header .store-name').html(`${translation.management_menu.menu_title}`)

            if (item.isManager || item.isBoss) {
                $('.management-menu .menu .side-bar div[data-href="employees"]').show();
                $('.management-menu .menu .side-bar div[data-href="boss-management"]').show();
                $('.management-menu').addClass(item.isManager && 'isManager' || '').removeClass(item.isBoss && 'isManager' || '').removeClass('isEmployee');
            } else {
                $('.management-menu .menu .side-bar div[data-href="employees"]').hide();
                $('.management-menu .menu .side-bar div[data-href="boss-management"]').hide();
                $('.management-menu').addClass('isEmployee');
            }

            // Announcements - loader:
            let announcementsData = loadAnnoucements(storeData.announcements);
            $('.management-menu div[data-type="main"] div[data-type="announcements"] .announcements-messages').html(announcementsData);

            // Total Earned - loader:
            $('.management-menu div[data-type="main"] div[data-type="total-earned"] .title').html(`${translation.currency} ${number.format(storeData.data.totalEarned)}`);

            // Employees - loader:
            let employeesData = loadEmployees(employees);
            $('.management-menu div[data-type="employees"] .box .data').html("");
            $('.management-menu div[data-type="employees"] tbody').html(employeesData);

            // Memberships - loader:
            $('.management-menu .side-bar div[data-href="memberships"]').hide();
            if (item.membershipsList) {
                $('.management-menu .side-bar div[data-href="memberships"]').show();
                $('.management-menu div[data-type="memberships"] .memberships-list').html(loadMemberships(item.membershipsList));
            }
            
            // Proteins - loader:
            $('.management-menu .side-bar div[data-href="proteins"]').hide();
            if (item.proteinsList) {
                $('.management-menu .side-bar div[data-href="proteins"]').show();
                $('.management-menu div[data-type="proteins"] .proteins-list').html(loadProteins(item.proteinsList));
            }

            // Balance - loader:
            if (useBuildInBalance) {
                loadBalance(storeData.data.balance);
            }

            // Employees Count - loader:
            $('.management-menu div[data-type="boss-management"] div[data-type="employees-count"] .title').html(`${item.employeesCount}`)

            // CityHall Resume's - loader:
            let isResumesAllowed = item.isResumesAllowed;
            if (isResumesAllowed != undefined) {
                if (item.isResumesAllowed) {
                    $('.management-menu div[data-type="resumes"] div[data-type="manage"] > .description > span').addClass('active')
                } else {
                    $('.management-menu div[data-type="resumes"] div[data-type="manage"] > .description > span').removeClass('active')
                }
                if (item.resumes) {
                    let resumesList = ``
                    let { CityHall_ResumesElement } = window.mySharedFunction();
                    for (const [_, data] of Object.entries(item.resumes)) {
                        let element = CityHall_ResumesElement;
                        resumesList += element.format(data.sender_name, formatDate(data.date), data.sender)
                    }
                    $('div[data-type="resumes"] .side-boxes > div[data-type="list"] > .resumes-list > table > tbody').html(resumesList);
                }
                $('.management-menu div[data-type="resumes"] div[data-type="manage"] > .description > span').html(isResumesAllowed ? translation.management_menu.resumes.manage_description_active : translation.management_menu.resumes.manage_description_not_active);
            }

            // CityHall Taxes - loader:
            let isTaxesAllowed = item.isTaxesAllowed;
            if (isTaxesAllowed != undefined) {
                if (item.taxes) {
                    let { LoadTaxesMenu } = window.mySharedFunction();
                    $('div[data-type="taxes"] .side-boxes > div[data-type="list"] > .taxes-list').html(LoadTaxesMenu(item.taxes, 'vms_gym'));
                }
            }

            if (cityhallGrades) {
                $('.management-menu .menu .side-bar div[data-href="resumes"]').hide();
                if (cityhallGrades['resumes']) {
                    $('.management-menu .menu .side-bar div[data-href="resumes"]').show();
                }
    
                $('.management-menu .menu .side-bar div[data-href="taxes"]').hide();
                if (cityhallGrades['taxes']) {
                    $('.management-menu .menu .side-bar div[data-href="taxes"]').show();
                }
            }

            currentMenu = 'management';
            updateManagement('main', `.management-menu .side-bar div[data-href="main"]`);
            $('.management-menu').fadeIn(120);
            // $('body').fadeIn(150);

            let announcementsChat = document.getElementById("announcements-chat");
            announcementsChat.scrollTop = announcementsChat.scrollHeight;
            break
        case 'closeManagementMenu':
            $('.management-menu').fadeOut(120);
        
            $(`div[data-type="main"]`).fadeOut(120);
            $(`div[data-type="employees"]`).fadeOut(120);
            $(`div[data-type="memberships"]`).fadeOut(120);
            $(`div[data-type="proteins"]`).fadeOut(120);
            $(`div[data-type="boss-management"]`).fadeOut(120);
            $(`div[data-type="resumes"]`).fadeOut(120);
            $(`div[data-type="taxes"]`).fadeOut(120);
            
            $('.btn[data-option="deposit"]').show();
            $('.btn[data-option="withdraw"]').show();
            
            $('input[data-input="withdraw"]').val('').hide();
            $('input[data-input="deposit"]').val('').hide();

            $('.box[data-type="balance"] .close-balance').removeClass('isAnyVal').removeClass('isVisible');
            $('.box[data-type="balance"] .close-balance > i').removeClass('fa-check').addClass('fa-close');
            break
        case 'updateManagementMenu':
            if (!currentMenu) return;
            if (item.storeData) storeData = item.storeData;

            $('.management-menu div[data-type="main"] div[data-type="announcements"] .announcements-messages').html(loadAnnoucements(storeData.announcements));
            let announcementsChatElement = document.getElementById("announcements-chat");
            announcementsChatElement.scrollTop = announcementsChatElement.scrollHeight;
            
            // Total Earned - loader:
            $('.management-menu div[data-type="main"] div[data-type="total-earned"] .title').html(`${translation.currency} ${number.format(storeData.data.totalEarned)}`);

            // Balance - loader:
            if (useBuildInBalance) {
                loadBalance(storeData.data.balance);
            }

            if (item.societyBalance) {
                loadBalance(Number(item.societyBalance));
            };

            if (item.employees) {
                employees = item.employees
                let employeesData = loadEmployees(employees);
                $('.management-menu div[data-type="employees"] tbody').html(employeesData)
            }

            if (item.taxes != undefined) {
                let { LoadTaxesMenu } = window.mySharedFunction();
                $('div[data-type="taxes"] .side-boxes > div[data-type="list"] > .taxes-list').html(LoadTaxesMenu(item.taxes, 'vms_gym'));
            }

            if (item.isResumesAllowed != undefined) {
                if (item.isResumesAllowed) {
                    $('.management-menu div[data-type="resumes"] div[data-type="manage"] > .description > span').addClass('active')
                } else {
                    $('.management-menu div[data-type="resumes"] div[data-type="manage"] > .description > span').removeClass('active')
                }
                $('.management-menu div[data-type="resumes"] div[data-type="manage"] > .description > span').html(item.isResumesAllowed ? translation.management_menu.resumes.manage_description_active : translation.management_menu.resumes.manage_description_not_active);
            }

            if (currentMenu == "employees" && item.players) {
                let players = item.players
                let hireData = ''
                $('.management-menu .main div[data-type="employees"] .box-right .data').html(`<div class="hire-list">${translation.management_menu.employees.menu_employees_no_players}</div>`);
                for (const [k, v] of Object.entries(players)) {
                    hireData += `
                        <div class="hire-player" data-playerid="${v}">
                            <div>${(translation.management_menu.employees.citizen).format(v)}</div>
                            <div class="hire_btn" onclick="hireEmployee(${v})">${translation.management_menu.employees.menu_option_hire_btn}</div>
                        </div>
                    `;
                };
                $('.management-menu .main div[data-type="employees"] .box-right .data .hire-list').html(hireData);
            }
            break
        case 'openReceipt':
            currentMenu = 'receipt';

            if (item.membershipData) {
                $('.receipt > .receipt-texts .list').append(`
                    <div class="product">
                        <div>${translation.management_menu.memberships.membership_for} ${item.membershipData.days ? `${item.membershipData.days} ${translation.days}` : ''} ${item.membershipData.hours ? `${item.membershipData.hours} ${translation.hours}` : ''}</div>
                        <div>
                            <span>${translation.currency}${!useCityHallIncludedTaxes && item.membershipData.totalAmount || item.membershipData.price}</span>
                        </div>
                    </div>
                `);
        
                $('.receipt > .receipt-texts .total > div:nth-child(2)').html(`
                    <span>${!useCityHallIncludedTaxes && item.membershipData.totalAmount || item.membershipData.price}${translation.currency}</span>
                `)

            } else if (item.proteinsData) {
                $('.receipt > .receipt-texts .list').append(`
                    <div class="product">
                        <div>${item.proteinsData.label} | ${item.count}x</div>
                        <div>
                            <span>${translation.currency}${!useCityHallIncludedTaxes && item.proteinsData.totalAmount || item.proteinsData.price}</span>
                        </div>
                    </div>
                `);
        
                $('.receipt > .receipt-texts .total > div:nth-child(2)').html(`
                    <span>${!useCityHallIncludedTaxes && item.proteinsData.totalAmount && (item.proteinsData.totalAmount * item.count) || (item.proteinsData.price * item.count)}${translation.currency}</span>
                `)

            }
    
            $('.receipt').fadeIn(150);
            break
        case 'closeReceipt':
            currentMenu = null;
            $('.receipt').fadeOut(150);
            $('.receipt > .receipt-texts .list').empty()
            break
	}
})

$('.close').click(function() {
	if (currentMenu == 'purchase_menu') {
		$.post(`https://${GetParentResourceName()}/closePurchaseMenu`);
	} else if (currentMenu == 'statistics') {
		$.post(`https://${GetParentResourceName()}/closeStatisticsMenu`);
	} else {
		$.post(`https://${GetParentResourceName()}/closeManagementMenu`, JSON.stringify({menu: currentMenu}));
	}
})

$('.back-to-menu').click(function() {
    $('.management-menu > .menu > .select-player, .management-menu > .menu > .select-player > div').fadeOut(120);
})

$('.status-button').click(function() {
    if ($(this).data('value') === 1) {
		$(`.statistics-menu #notification-status div[data-value=0]`).removeClass('status-button-active')
    } else {
		$(`.statistics-menu #notification-status div[data-value=1]`).removeClass('status-button-active')
	}
	$(this).addClass('status-button-active')
	localStorage.setItem(`notify-status`, $(this).data('value'));
	$.post(`https://${GetParentResourceName()}/notifyStatus`, JSON.stringify({status: localStorage.getItem("notify-status")}));
})

$('.purchase-menu .header .proteins').click(function() {
	$('.purchase-menu .header .memberships').removeClass('active');
	$(this).addClass('active')
	$('.purchase-menu .memberships-menu').hide();
	$('.purchase-menu .proteins-menu').show();
	
})

$('.purchase-menu .header .memberships').click(function() {
	$('.purchase-menu .header .proteins').removeClass('active');
	$(this).addClass('active')
	$('.purchase-menu .proteins-menu').hide();
	$('.purchase-menu .memberships-menu').show();

})

const buyProtein = (name) => {
	$.post(`https://${GetParentResourceName()}/buyProtein`, JSON.stringify({name: name}));
}

const buyMembership = (days, hours) => {
	$.post(`https://${GetParentResourceName()}/buyMembership`, JSON.stringify({
		days:days, hours:hours
	}));
}

const sellMembership = (days, hours, playerId) => {
    if (playerId) {
	    $.post(`https://${GetParentResourceName()}/sellMembership`, JSON.stringify({
            days: days,
            hours: hours,
            playerId: playerId
        }));
        $('.management-menu > .menu > .select-player, .management-menu > .menu > .select-player > div').fadeOut(120);
    } else {
        let _days = days;
        let _hours = hours;
        $('.management-menu .select-player .header > .name').html(`${translation.management_menu.memberships.membership_for} ${_days ? `${_days} ${translation.days}` : ''} ${_hours ? `${_hours} ${translation.hours}` : ''}`);
        $.post(`https://${GetParentResourceName()}/getClosestPlayersForMembership`, JSON.stringify({}), function(players) {
            let playersData = ``
            for (const [k, v] of Object.entries(players)) {
                playersData += `
                    <div>
                        <div class="player">
                            <p>${(translation.management_menu.select_players.citizen).format(v)}</p>
                        </div>
                        <div class="action" onclick="sellMembership(${_days}, ${_hours}, ${v})">
                            <p>${translation.management_menu.select_players.provide_bill}</p>
                        </div>
                    </div>
                `
            }
            $('.management-menu > .menu > .select-player > div > .menu').html(playersData);
            $('.management-menu > .menu > .select-player > div').fadeIn(120);
            $('.management-menu > .menu > .select-player').css({'display': 'flex'});
        });
    }
}

const sellProtein = (name, label, playerId) => {
    let count = $(`#${name}-count`).val()
    if (count < 1) return;
    if (playerId) {
	    $.post(`https://${GetParentResourceName()}/sellProtein`, JSON.stringify({
            name: name,
            count: count,
            playerId: playerId
        }));
        $(`#${name}-count`).val('');
        $('.management-menu > .menu > .select-player, .management-menu > .menu > .select-player > div').fadeOut(120);
    } else {
        let _name = name;
        $('.management-menu .select-player .header > .name').html(`${label} ${count}x`);
        $.post(`https://${GetParentResourceName()}/getClosestPlayersForMembership`, JSON.stringify({}), function(players) {
            let playersData = ``
            for (const [k, v] of Object.entries(players)) {
                playersData += `
                    <div>
                        <div class="player">
                            <p>${(translation.management_menu.select_players.citizen).format(v)}</p>
                        </div>
                        <div class="action" onclick="sellProtein('${_name}', null, ${v})">
                            <p>${translation.management_menu.select_players.provide_bill}</p>
                        </div>
                    </div>
                `
            }
            $('.management-menu > .menu > .select-player > div > .menu').html(playersData);
            $('.management-menu > .menu > .select-player > div').fadeIn(120);
            $('.management-menu > .menu > .select-player').css({'display': 'flex'});
        });
    }
}

const proteinOnChange = (data, name, price) => {
    let value = $(data).val()
    if (price && price >= 1 && value >= 1) {
        $(`#${name}-price`).html(`${translation.currency}${price * value}`)
    }
}

$(document).on('click', '.management-menu .side-bar .button', function(e) {
    let newMenu = $(this).data('href')
    updateManagement(newMenu, this)
})

function updateManagementSub(newMenu, _this) {
    if (newMenu == currentMenu) return;
    
    if (_this != selectedOption) {
        if (selectedOption) {
            $(selectedOption).removeClass("selected");
        }
        selectedOption = _this
        $(selectedOption).addClass("selected");
    }

    $(`div[data-type="${currentMenu}"]`).hide();

    currentMenu = newMenu
    $(`div[data-type="${currentMenu}"]`).show();

}

function updateManagement(newMenu, _this) {
    if (newMenu == currentMenu) return;

    if (newMenu != "employees") {
        $('.management-menu .main div[data-type="employees"] .box-right .data').empty();
    }

    if (_this != selectedOption) {
        if (selectedOption) {
            $(selectedOption).removeClass("selected");
        }
        selectedOption = _this
        $(selectedOption).addClass("selected");
    }
    
    $(`div[data-type="${currentMenu}"]`).hide();
    currentMenu = newMenu
    $(`div[data-type="${currentMenu}"]`).show();
}

function hireEmployee(playerId) {
    if (playerId) {
        $.post(`https://${GetParentResourceName()}/hireEmployee`, JSON.stringify({playerId: playerId}));
    }
}

function bonusEmployee(identifier) {
    let bonusMoney = $("#bonus-money").val();
    if (identifier && bonusMoney && bonusMoney >= 1) {
        $.post(`https://${GetParentResourceName()}/bonusEmployee`, JSON.stringify({identifier: identifier, bonusMoney: bonusMoney}));
        $("#bonus-money").val('');
    }
}

function changeGradeEmployee(identifier, grade) {
    if (identifier && grade) {
        $.post(`https://${GetParentResourceName()}/changeGradeEmployee`, JSON.stringify({identifier: identifier, grade: grade}));
    }
}

function fireEmployee(identifier) {
    if (identifier) {
        $.post(`https://${GetParentResourceName()}/fireEmployee`, JSON.stringify({identifier: identifier}));
        $('.management-menu .main div[data-type="employees"] .box-right .data').empty();
    }
}

function manageEmployee(name, identifier) {
    let jobsToSet = ``
    for (const [key, job] of Object.entries(storeCfg.jobGradesToSet)) {
        if (job) {
            jobsToSet += `
                <div>
                    <div class="changegrade" onclick='changeGradeEmployee("${identifier}", ${
                        JSON.stringify(job)
                    })'>${translation.management_menu.employees.menu_option_setjob_btn + job.label}</div>
                </div>
            `
        }
    }
    
    $('.management-menu .main div[data-type="employees"] .box-right .data').html(`
        <div class="employee-manage">
            <div class="player">
                <div class="player-name">${name}</div>
                <div class="bonus-bar">
                    <input type="number" id="bonus-money">
                    <div class="bonus" onclick="bonusEmployee('${identifier}')">${translation.management_menu.employees.menu_option_bonus_btn}</div>
                </div>
                ${jobsToSet}
                <div>
                    <div class="fire" onclick="fireEmployee('${identifier}')">${translation.management_menu.employees.menu_option_fire_btn}</div>
                </div>
                
            </div>
        </div>
    `);
}

$(".btn").click(function() {
    let option = $(this).data('option')
    if (option == 'send-announce') {
        let text = $('textarea[data-type="announcement"]').val();
        message = text.trim();
        if (message !== "") {
            $.post(`https://${GetParentResourceName()}/sendAnnouncement`, JSON.stringify({text: text}));
            $('textarea[data-type="announcement"]').val("")
        }
    } else if (option == "withdraw") {
        $('.box[data-type="balance"] .close-balance').addClass('isVisible');
        $('input[data-input="withdraw"]').show();
        $('.btn[data-option="deposit"]').hide();
        $('.btn[data-option="withdraw"]').hide();
    } else if (option == "deposit") {
        $('.box[data-type="balance"] .close-balance').addClass('isVisible');
        $('input[data-input="deposit"]').show();
        $('.btn[data-option="deposit"]').hide();
        $('.btn[data-option="withdraw"]').hide();
    } else if (option == "get_closest_players") {
        $.post(`https://${GetParentResourceName()}/getClosestPlayers`);
    } else if (option == "employees") {
        updateManagementSub(option, `div[data-href="employees"]`)
    }
})

function balanceButton() {
    if ($('input[data-input="withdraw"]').val() >= 1) {
        let money = $('input[data-input="withdraw"]').val()
        $.post(`https://${GetParentResourceName()}/withdraw`, JSON.stringify({money: money}));
        $('input[data-input="withdraw"]').val('').hide();
        $('.btn[data-option="deposit"]').show();
        $('.btn[data-option="withdraw"]').show();
        $('.box[data-type="balance"] .close-balance').removeClass('isAnyVal');
        $('.box[data-type="balance"] .close-balance > i').removeClass('fa-check').addClass('fa-close');
        $('.box[data-type="balance"] .close-balance').removeClass('isVisible');
    } else if ($('input[data-input="deposit"]').val() >= 1) {
        let money = $('input[data-input="deposit"]').val()
        $.post(`https://${GetParentResourceName()}/deposit`, JSON.stringify({money: money}));
        $('input[data-input="deposit"]').val('').hide();
        $('.btn[data-option="deposit"]').show();
        $('.btn[data-option="withdraw"]').show();
        $('.box[data-type="balance"] .close-balance').removeClass('isAnyVal');
        $('.box[data-type="balance"] .close-balance > i').removeClass('fa-check').addClass('fa-close');
        $('.box[data-type="balance"] .close-balance').removeClass('isVisible');
    } else {
        $('.btn[data-option="deposit"]').show();
        $('.btn[data-option="withdraw"]').show();
        $('input[data-input="withdraw"]').val('').hide();
        $('input[data-input="deposit"]').val('').hide();
        $('.box[data-type="balance"] .close-balance').removeClass('isVisible');
    }
}

function onInputBalance(type) {
    let value = $(`input[data-input="${type}"]`).val();
    if (type == 'withdraw') {
        if (value >= 1) {
            $('.box[data-type="balance"] .close-balance').addClass('isAnyVal');
            $('.box[data-type="balance"] .close-balance > i').removeClass('fa-close').addClass('fa-check');
            
        } else {
            $('.box[data-type="balance"] .close-balance').removeClass('isAnyVal');
            $('.box[data-type="balance"] .close-balance > i').removeClass('fa-check').addClass('fa-close');

        }
    } else if (type == 'deposit') {
        if (value >= 1) {
            $('.box[data-type="balance"] .close-balance').addClass('isAnyVal');
            $('.box[data-type="balance"] .close-balance > i').removeClass('fa-close').addClass('fa-check');
            
        } else {
            $('.box[data-type="balance"] .close-balance').removeClass('isAnyVal');
            $('.box[data-type="balance"] .close-balance > i').removeClass('fa-check').addClass('fa-close');

        }
    }
}

$(document).on('click', '.receipt .buttons .pay_cash', function(e) {
    $.post(`https://${GetParentResourceName()}/bill`, JSON.stringify({
        action: 'pay',
        type: 'cash',
    }));
})

$(document).on('click', '.receipt .buttons .pay_bank', function(e) {
    $.post(`https://${GetParentResourceName()}/bill`, JSON.stringify({
        action: 'pay',
        type: 'bank',
    }));
})

$(document).on('click', '.receipt .buttons .cancel', function(e) {
    $.post(`https://${GetParentResourceName()}/bill`, JSON.stringify({
        action: 'cancel'
    }));
})