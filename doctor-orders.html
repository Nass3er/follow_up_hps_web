<!DOCTYPE html>
<html lang="ar" dir="rtl">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>أوامر الأطباء - HPS</title>
    <link rel="stylesheet" href="assets/css/style.css">
    <link href="https://fonts.googleapis.com/css2?family=Tajawal:wght@400;500;700&display=swap" rel="stylesheet">
    <link rel="manifest" href="manifest.json">
    <meta name="theme-color" content="#1565c0">
    <meta name="mobile-web-app-capable" content="yes">
    <meta name="apple-mobile-web-app-capable" content="yes">
    <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">
    <link rel="apple-touch-icon" href="icon.png">
    <style>
        .input-group {
            display: flex;
            align-items: center;
            gap: 5px;
        }

        .input-group input {
            flex: 1;
        }

        .input-group label {
            margin-bottom: 0;
            width: 80px;
            font-size: 14px;
        }

        /* Specific sizing */
        #doctor-name,
        #patient-name {
            flex: 2;
            background: #eee;
        }

        .mini-search-btn {
            background-color: #3498db;
            color: #fff;
            border: none;
            border-radius: 4px;
            padding: 5px 10px;
            cursor: pointer;
        }

        .mandatory-field {
            background-color: #fffde7 !important; /* أبيض مائل للأصفر */
            border: 1px solid #fbc02d !important;
        }

        .mandatory-field:focus {
            background-color: #fff9c4 !important;
            border-color: #f9a825 !important;
            box-shadow: 0 0 5px rgba(249, 168, 37, 0.3) !important;
        }
    </style>
</head>

<body>
    <div class="app-layout">
        <nav class="top-nav">
            <div class="brand">
                <h1 style="font-size: 18px;">📋 أوامر الأطباء</h1>
            </div>
            <div class="nav-actions">
                <a href="javascript:void(0)" onclick="goBack()" class="btn btn-secondary" style="text-decoration:none; font-size: 20px; padding: 5px 12px;">➡</a>
                <div class="user-info">
                    <span id="cur-day"></span> - <span id="cur-date"></span>
                </div>
            </div>
        </nav>

        <main class="main-content">
            <div class="action-bar">
                <button class="btn btn-success" id="btn-add" onclick="addNewOrder()">➕ إضافة</button>
                <button class="btn btn-warning" id="btn-edit" onclick="enableEditing()" disabled>✏️ تعديل</button>
                <button class="btn btn-danger" id="btn-delete" onclick="deleteOrder()" disabled>🗑️ حذف</button>
                <button class="btn btn-primary" id="btn-search-orders" onclick="openHistoryModal()">🔍 بحث الأوامر</button>
            </div>

            <!-- قسم المعلومات الاساسية للامر (Master) -->
            <section class="card section-search" style="padding: 10px;">
                <div class="grid-2" style="margin-bottom: 10px;">
                    <div class="form-group">
                        <label style="font-weight: 700;">رقم الترقيد</label>
                        <div class="input-with-btn">
                            <input type="number" id="adm-no-input" class="mandatory-field" placeholder="رقم الترقيد" style="height: 38px;">
                            <button onclick="openAdmModal()" class="btn btn-primary" title="بحث" style="padding: 0 10px;">🔍</button>
                        </div>
                    </div>
                    <div class="form-group">
                        <label style="color: var(--primary); font-weight: 700;">نوع الإجراء الطبي</label>
                        <select id="prcdr-typ" class="mandatory-field" onchange="onProcedureTypeChanged()" style="border: 2px solid var(--primary); height: 38px; padding: 5px 8px;">
                            <option value="">-- اختر النوع --</option>
                        </select>
                    </div>
                </div>

                <details>
                    <summary style="cursor: pointer; color: #7f8c8d; font-size: 13px;">⚙️ إعدادات الأمر الإضافية (رقم الأمر، التاريخ، الفرع...)</summary>
                    <div class="grid-2" style="margin-top: 10px;">
                        <div class="form-group">
                            <label>الفرع</label>
                            <select id="branch-list" class="mandatory-field"></select>
                        </div>
                        <div class="form-group"><label>رقم الأمر</label><input type="number" id="doc-no" value="1"></div>
                        <div class="form-group"><label>تاريخ الأمر</label><input type="date" id="doc-date"></div>
                        <div class="form-group"><label>وقت الأمر</label><input type="time" id="doc-time" value="00:00:00" step="1"></div>
                        <div class="form-group">
                            <label>الأولوية</label>
                            <select id="prorty-no">
                                <option value="1">1- عادي</option>
                                <option value="2">2- مستعجل</option>
                                <option value="3">3- حرجة</option>
                            </select>
                        </div>
                        <div class="form-group">
                            <label>رقم المرجع (اختياري)</label>
                            <input type="text" id="ref-no">
                        </div>
                        <div class="form-group full-width">
                            <label>ملاحظة عامة</label>
                            <textarea id="doc-dsc" rows="2"></textarea>
                        </div>
                        <input type="hidden" id="typ-no" value="1"><input type="hidden" id="ptnt-typ" value="1">
                    </div>
                </details>
            </section>

            <!-- تفاصيل بيانات الترقيد المحددة ستظهر هنا -->
            <!-- تفاصيل بيانات الترقيد ستبقى مخفية تماماً كما طلب المستخدم -->
            <section id="patient-info-section" style="display: none !important;">
                <div class="patient-grid">
                    <input type="hidden" id="patient-no">
                    <input type="hidden" id="patient-name">
                    <input type="hidden" id="doctor-no">
                    <input type="hidden" id="doctor-name">
                    <input type="hidden" id="p-room">
                    <input type="hidden" id="p-bed">
                    <input type="hidden" id="p-dept">
                    <input type="hidden" id="p-gender">
                    <input type="hidden" id="p-age">
                    <input type="hidden" id="p-adm-date">
                </div>
            </section>

            <!-- قسم التفاصيل (Details) -->
            <section id="table-area" class="card" style="display: none;">
                <div class="table-header">
                    <h3 class="section-title" id="details-title">📋 تفاصيل الإجراء</h3>
                </div>
                <div class="table-responsive" style="overflow-x: auto;">
                    <table id="details-table" class="modern-table" style="min-width: 800px;">
                        <thead>
                            <tr id="details-thead-tr">
                                <!-- سيتم بناؤه ديناميكياً بواسطة JS حسب نوع الإجراء -->
                            </tr>
                        </thead>
                        <tbody id="details-tbody">
                            <!-- صفوف التفاصيل -->
                        </tbody>
                    </table>
                </div>

                <div style="margin-top: 25px; text-align: center; padding: 15px; background: var(--card-bg); border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.05);">
                    <button class="btn btn-success" id="btn-save" onclick="saveOrder()"
                        style="padding: 12px 40px; font-weight: bold; font-size: 16px; width: 100%; max-width: 300px;">💾 حفظ</button>
                </div>
            </section>
        </main>
    </div>

    <!-- Modals -->
    <!-- نافذة البحث في الترقيدات -->
    <div id="modal-adm" class="modal">
        <div class="modal-content">
            <div class="modal-header">
                <h3>قائمة الترقيدات</h3>
                <span class="close-btn" onclick="closeModal('modal-adm')">&times;</span>
            </div>
            <div style="padding: 10px;">
                <input type="text" id="adm-search-input" placeholder="ابحث باسم المريض أو رقم الترقيد..."
                    style="width: 100%; border: 1px solid #ddd; padding: 10px; border-radius: 5px;"
                    onkeyup="filterAdmissions()">
            </div>
            <div class="table-responsive" style="max-height: 400px; overflow-y: auto;">
                <table id="adm-list-table" class="modern-table">
                    <thead>
                        <tr>
                            <th>رقم الترقيد</th>
                            <th>تاريخ الترقيد</th>
                            <th>اسم المريض</th>
                        </tr>
                    </thead>
                    <tbody></tbody>
                </table>
            </div>
            <div class="modal-footer">
                <button onclick="closeModal('modal-adm')" class="btn btn-secondary">إغلاق</button>
            </div>
        </div>
    </div>

    <!-- نافذة منبثقة للبحث في الإجراءات (فحوصات / أشعة الخ) -->
    <div id="modal-items" class="modal">
        <div class="modal-content modal-lg">
            <div class="modal-header">
                <h3 id="modal-items-title">قائمة الإجراءات مسبقة الصنع</h3>
                <span class="close-btn" onclick="closeModal('modal-items')">&times;</span>
            </div>
            <div style="padding: 10px;">
                <input type="text" id="item-search-input" placeholder="ابحث بالإسم أو الكود هنا..."
                    style="width: 100%; border: 1px solid #ddd; padding: 10px; border-radius: 5px;"
                    onkeyup="filterItems()">
            </div>
            <div class="table-responsive" style="max-height: 400px; overflow-y: auto;">
                <table id="items-list-table" class="modern-table">
                    <thead>
                        <tr id="items-thead-tr">
                            <!-- مبني ديناميكيا -->
                        </tr>
                    </thead>
                    <tbody id="items-tbody"></tbody>
                </table>
            </div>
            <div class="modal-footer">
                <button onclick="closeModal('modal-items')" class="btn btn-secondary">إغلاق</button>
            </div>
        </div>
    </div>

    <!-- نافذة منبثقة للبحث في طرق الاستخدام -->
    <div id="modal-usages" class="modal">
        <div class="modal-content">
            <div class="modal-header">
                <h3>قائمة طرق الاستخدام</h3>
                <span class="close-btn" onclick="closeModal('modal-usages')">&times;</span>
            </div>
            <div style="padding: 10px;">
                <input type="text" id="usage-search-input" placeholder="ابحث بالرمز أو الوصف هنا..."
                    style="width: 100%; border: 1px solid #ddd; padding: 10px; border-radius: 5px;"
                    onkeyup="filterUsages()">
            </div>
            <div class="table-responsive" style="max-height: 400px; overflow-y: auto;">
                <table id="usages-list-table" class="modern-table">
                    <thead>
                        <tr>
                            <th>الرمز</th>
                            <th>الوصف</th>
                        </tr>
                    </thead>
                    <tbody id="usages-tbody"></tbody>
                </table>
            </div>
            <div class="modal-footer">
                <button onclick="closeModal('modal-usages')" class="btn btn-secondary">إغلاق</button>
            </div>
        </div>
    </div>

    <!-- نافذة البحث في الأوامر السابقة -->
    <div id="modal-history" class="modal">
        <div class="modal-content modal-lg">
            <div class="modal-header">
                <h3>الأوامر السابقة</h3>
                <span class="close-btn" onclick="closeModal('modal-history')">&times;</span>
            </div>
            <div style="padding: 10px;">
                <input type="text" id="history-search-input" placeholder="ابحث في أي عمود هنا..."
                    style="width: 100%; border: 1px solid #ddd; padding: 10px; border-radius: 5px;"
                    onkeyup="filterHistory()">
            </div>
            <div class="table-responsive" style="max-height: 400px; overflow-y: auto;">
                <table id="history-list-table" class="modern-table">
                    <thead>
                        <tr>
                            <th>رقم الأمر</th>
                            <th>التاريخ</th>
                            <th>نوع الإجراء</th>
                            <th>اسم الطبيب</th>
                            <th>اسم المريض</th>
                        </tr>
                    </thead>
                    <tbody></tbody>
                </table>
            </div>
        </div>
    </div>

    <!-- Scripts -->
    <script src="assets/js/config.js"></script>
    <script src="assets/js/db.js"></script>
    <script src="assets/js/sync.js"></script>
    <script src="assets/js/doctor_orders.js"></script>
</body>

</html>