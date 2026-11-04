import os

with open('docs/reader.html', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. HTML Replacement for Tab 2
tab2_html = '''        <!-- TAB 2: Roadmap & Plan (Integer Target Days & Real-Time Dynamic Pace) -->
        <div id="plannerViewRoadmap" class="hidden space-y-4">
          <div class="p-4 rounded-2xl bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 space-y-3.5 shadow-sm">
            <div class="flex items-center justify-between pb-2 border-b border-slate-200 dark:border-slate-700">
              <h3 class="text-sm font-bold text-slate-900 dark:text-white flex items-center gap-2">
                <span id="cycleViewIcon">🎯</span>
                <span id="cycleViewTitle">কাস্টম খতম ও দাওর রোডম্যাপ</span>
              </h3>
              <span class="text-[11px] font-bold text-emerald-700 dark:text-emerald-400 font-mono">৬১২ পৃষ্ঠা</span>
            </div>

            <p id="cycleViewDesc" class="text-xs text-slate-600 dark:text-slate-400 leading-relaxed">
              আপনার সুবিধাজনক দিন সংখ্যা লিখুন। আপনি ইতিমধ্যে যত পৃষ্ঠা পড়েছেন তার ওপর ভিত্তি করে বাকি পড়ার রিয়েল-টাইম দৈনিক গতি বণ্টন করা হবে।
            </p>

            <div class="space-y-3 pt-1">
              <!-- Integer Target Time (Days) Input -->
              <div>
                <label id="cycleTargetDaysLabel" class="text-xs font-bold text-slate-700 dark:text-slate-300 block mb-1">
                  টার্গেট সময়সীমা (পূর্ণসংখ্যা দিন):
                </label>
                <div class="flex items-center gap-1.5">
                  <button type="button" id="decTargetDaysBtn" class="w-10 h-10 rounded-xl bg-slate-200 dark:bg-slate-700 font-bold text-lg hover:bg-slate-300 transition flex items-center justify-center select-none">-</button>
                  <input type="number" id="cycleTargetDaysInput" min="1" max="1000" value="30" 
                         class="flex-1 text-center py-2 px-3 rounded-xl border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-900 text-sm sm:text-base font-bold font-mono">
                  <button type="button" id="incTargetDaysBtn" class="w-10 h-10 rounded-xl bg-slate-200 dark:bg-slate-700 font-bold text-lg hover:bg-slate-300 transition flex items-center justify-center select-none">+</button>
                </div>
              </div>

              <!-- Quick Target Chips -->
              <div class="flex items-center gap-1.5 overflow-x-auto pb-1 no-scrollbar text-xs">
                <span class="text-[10px] text-slate-500 shrink-0 font-medium">কুইক দিন:</span>
                <button type="button" onclick="setTargetDaysVal(3)" class="px-2.5 py-1 rounded-lg bg-slate-100 dark:bg-slate-800 hover:bg-emerald-100 text-emerald-800 dark:text-emerald-300 text-[11px] font-semibold border border-slate-200 dark:border-slate-700 transition shrink-0">৩ দিন</button>
                <button type="button" onclick="setTargetDaysVal(5)" class="px-2.5 py-1 rounded-lg bg-slate-100 dark:bg-slate-800 hover:bg-emerald-100 text-emerald-800 dark:text-emerald-300 text-[11px] font-semibold border border-slate-200 dark:border-slate-700 transition shrink-0">৫ দিন</button>
                <button type="button" onclick="setTargetDaysVal(7)" class="px-2.5 py-1 rounded-lg bg-slate-100 dark:bg-slate-800 hover:bg-emerald-100 text-emerald-800 dark:text-emerald-300 text-[11px] font-semibold border border-slate-200 dark:border-slate-700 transition shrink-0">৭ দিন</button>
                <button type="button" onclick="setTargetDaysVal(10)" class="px-2.5 py-1 rounded-lg bg-slate-100 dark:bg-slate-800 hover:bg-emerald-100 text-emerald-800 dark:text-emerald-300 text-[11px] font-semibold border border-slate-200 dark:border-slate-700 transition shrink-0">১০ দিন</button>
                <button type="button" onclick="setTargetDaysVal(15)" class="px-2.5 py-1 rounded-lg bg-slate-100 dark:bg-slate-800 hover:bg-emerald-100 text-emerald-800 dark:text-emerald-300 text-[11px] font-semibold border border-slate-200 dark:border-slate-700 transition shrink-0">১৫ দিন</button>
                <button type="button" onclick="setTargetDaysVal(20)" class="px-2.5 py-1 rounded-lg bg-slate-100 dark:bg-slate-800 hover:bg-emerald-100 text-emerald-800 dark:text-emerald-300 text-[11px] font-semibold border border-slate-200 dark:border-slate-700 transition shrink-0">২০ দিন</button>
                <button type="button" onclick="setTargetDaysVal(30)" class="px-2.5 py-1 rounded-lg bg-slate-100 dark:bg-slate-800 hover:bg-emerald-100 text-emerald-800 dark:text-emerald-300 text-[11px] font-semibold border border-slate-200 dark:border-slate-700 transition shrink-0">৩০ দিন</button>
                <button type="button" onclick="setTargetDaysVal(60)" class="px-2.5 py-1 rounded-lg bg-slate-100 dark:bg-slate-800 hover:bg-emerald-100 text-emerald-800 dark:text-emerald-300 text-[11px] font-semibold border border-slate-200 dark:border-slate-700 transition shrink-0">৬০ দিন</button>
                <button type="button" onclick="setTargetDaysVal(90)" class="px-2.5 py-1 rounded-lg bg-slate-100 dark:bg-slate-800 hover:bg-emerald-100 text-emerald-800 dark:text-emerald-300 text-[11px] font-semibold border border-slate-200 dark:border-slate-700 transition shrink-0">৯০ দিন</button>
              </div>

              <!-- Start Para and Date -->
              <div class="grid grid-cols-2 gap-3">
                <div>
                  <label class="text-xs font-bold text-slate-700 dark:text-slate-300">শুরুর পারা (১-৩০):</label>
                  <input type="number" id="cycleStartParaInput" min="1" max="30" value="1" 
                         class="w-full mt-1 px-3 py-2 rounded-xl border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-900 text-xs font-mono font-bold">
                </div>
                <div>
                  <label class="text-xs font-bold text-slate-700 dark:text-slate-300">শুরুর তারিখ:</label>
                  <input type="date" id="cycleStartDateInput" class="w-full mt-1 px-3 py-2 rounded-xl border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-900 text-xs font-mono">
                </div>
              </div>

              <!-- Live Dynamic Calculation Card -->
              <div id="liveRoadmapPreviewCard" class="p-3.5 rounded-2xl bg-emerald-50 dark:bg-emerald-950/50 border border-emerald-500/30 space-y-2 text-xs">
                <div class="flex items-center justify-between text-slate-700 dark:text-slate-300">
                  <span class="font-medium">অবশিষ্ট পড়ার পরিমাণ:</span>
                  <span id="liveRemainingPagesText" class="font-bold text-emerald-800 dark:text-emerald-300 font-mono">৬১২ পৃষ্ঠা (৩০.০ পারা)</span>
                </div>
                <div class="flex items-center justify-between text-slate-700 dark:text-slate-300">
                  <span class="font-medium">টার্গেট অনুযায়ী দৈনিক গতি:</span>
                  <span id="liveDailyRequiredText" class="font-bold text-emerald-800 dark:text-emerald-300 font-mono">২১ পৃষ্ঠা/দিন (১.০ পারা)</span>
                </div>
                <div class="flex items-center justify-between text-slate-700 dark:text-slate-300 pt-1 border-t border-emerald-500/20">
                  <span class="font-medium">সম্ভাব্য সমাপ্তির তারিখ:</span>
                  <span id="liveEstimatedEndDateText" class="font-bold text-gold-600 dark:text-gold-400 font-mono">--</span>
                </div>
              </div>

              <button id="generateCycleBtn" class="w-full py-2.5 bg-emerald-700 hover:bg-emerald-600 text-white rounded-xl text-xs sm:text-sm font-semibold transition shadow-md">
                রোডম্যাপ তৈরি সম্পন্ন করুন
              </button>
            </div>
          </div>

          <div id="cycleSummaryBox" class="hidden p-4 rounded-2xl bg-emerald-900 text-white space-y-1.5 shadow-md">
            <div id="cycleSummaryTitle" class="text-xs font-bold text-gold-300">✓ রোডম্যাপ সফলভাবে প্রস্তুত হয়েছে!</div>
            <p id="cycleSummaryText" class="text-xs text-emerald-100 leading-relaxed"></p>
          </div>

          <!-- Tilawat Tips Card -->
          <div class="p-4 rounded-2xl bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 space-y-2 text-xs text-slate-600 dark:text-slate-400 leading-relaxed">
            <div class="font-bold text-emerald-800 dark:text-emerald-300">💡 ডায়নামিক হিসাব পরামর্শ:</div>
            <p>১. যে কোনো পূর্ণসংখ্যা দিন (যেমন: ৩, ৫, ৭, ১২, ২৫ বা ৪০ দিন) লিখে ইচ্ছামতো রুটিন সাজানো যায়।</p>
            <p>২. কোনো দিন বেশি বা কম পড়া হলে অবশিষ্ট পৃষ্ঠা বাকি দিনগুলোতে স্বয়ংক্রিয়ভাবে সমন্বিত হবে।</p>
            <p>৩. মোট ৬১২ পৃষ্ঠার হাফেজী কুরআন সমাপ্ত হলে স্বয়ংক্রিয়ভাবে ১০০% খতম সফল হবে।</p>
          </div>
        </div>
'''

# 2. JavaScript Replacement for Tab 2
tab2_js = '''    // TAB 2: Roadmap Generator (Integer Input & Real-Time Dynamic Calculation)
    function renderPlannerRoadmapView() {
      const targetDaysInput = document.getElementById('cycleTargetDaysInput');
      const startDateInput = document.getElementById('cycleStartDateInput');

      if (targetDaysInput && !targetDaysInput.value) {
        targetDaysInput.value = plannerState.targetDays || 30;
      }
      if (startDateInput && !startDateInput.value) {
        startDateInput.value = formatDateKey(new Date());
      }
      updateLiveRoadmapPreview();
    }

    function updateLiveRoadmapPreview() {
      const targetDaysInput = document.getElementById('cycleTargetDaysInput');
      const startDateInput = document.getElementById('cycleStartDateInput');
      const remPagesEl = document.getElementById('liveRemainingPagesText');
      const dailyReqEl = document.getElementById('liveDailyRequiredText');
      const endDscEl = document.getElementById('liveEstimatedEndDateText');

      if (!targetDaysInput) return;

      const targetDays = Math.max(1, parseInt(targetDaysInput.value, 10) || 30);
      const stats = calculateKhatamStats();

      if (remPagesEl) {
        remPagesEl.textContent = `${toBnNum(stats.remainingPages)} পৃষ্ঠা (${toBnNum(stats.remainingParas)} পারা)`;
      }

      const dailyPages = Math.ceil(stats.remainingPages / targetDays);
      const dailyParas = (dailyPages / 20.4).toFixed(1);

      if (dailyReqEl) {
        dailyReqEl.textContent = `${toBnNum(dailyPages)} পৃষ্ঠা/দিন (${toBnNum(dailyParas)} পারা)`;
      }

      const startDateVal = startDateInput ? startDateInput.value : '';
      const startDate = startDateVal ? new Date(startDateVal) : new Date();
      const endDate = new Date(startDate);
      endDate.setDate(endDate.getDate() + targetDays);

      if (endDscEl) {
        endDscEl.textContent = `${toBnNum(endDate.getDate())} ${GREGORIAN_MONTHS_BN[endDate.getMonth()]} ${toBnNum(endDate.getFullYear())}`;
      }
    }

    const cycleTargetDaysInput = document.getElementById('cycleTargetDaysInput');
    const cycleStartDateInput = document.getElementById('cycleStartDateInput');

    if (cycleTargetDaysInput) {
      cycleTargetDaysInput.addEventListener('input', updateLiveRoadmapPreview);
    }
    if (cycleStartDateInput) {
      cycleStartDateInput.addEventListener('change', updateLiveRoadmapPreview);
    }

    const decTargetDaysBtn = document.getElementById('decTargetDaysBtn');
    const incTargetDaysBtn = document.getElementById('incTargetDaysBtn');

    if (decTargetDaysBtn && cycleTargetDaysInput) {
      decTargetDaysBtn.addEventListener('click', () => {
        let v = parseInt(cycleTargetDaysInput.value, 10) || 30;
        if (v > 1) cycleTargetDaysInput.value = v - 1;
        updateLiveRoadmapPreview();
      });
    }
    if (incTargetDaysBtn && cycleTargetDaysInput) {
      incTargetDaysBtn.addEventListener('click', () => {
        let v = parseInt(cycleTargetDaysInput.value, 10) || 30;
        if (v < 1000) cycleTargetDaysInput.value = v + 1;
        updateLiveRoadmapPreview();
      });
    }

    window.setTargetDaysVal = function(days) {
      if (cycleTargetDaysInput) {
        cycleTargetDaysInput.value = days;
        updateLiveRoadmapPreview();
      }
    };

    const generateCycleBtn = document.getElementById('generateCycleBtn');
    if (generateCycleBtn) {
      generateCycleBtn.addEventListener('click', () => {
        const targetDays = Math.max(1, parseInt(document.getElementById('cycleTargetDaysInput').value, 10) || 30);
        const startPara = parseInt(document.getElementById('cycleStartParaInput').value, 10) || 1;
        const startDateVal = document.getElementById('cycleStartDateInput').value;
        const startDate = startDateVal ? new Date(startDateVal) : new Date();

        plannerState.targetDays = targetDays;

        const stats = calculateKhatamStats();
        const pagesToDistribute = stats.remainingPages;
        const dailyTargetPages = Math.ceil(pagesToDistribute / targetDays);

        let d = new Date(startDate);

        for (let i = 0; i < targetDays; i++) {
          const dKey = formatDateKey(d);
          if (!plannerState.logs[dKey]) plannerState.logs[dKey] = { notes: [] };

          if (!plannerState.logs[dKey].totalDayPages) {
            plannerState.logs[dKey].generalTilawat = `টার্গেট: ${toBnNum(dailyTargetPages)} পৃষ্ঠা`;
          }
          if (!plannerState.logs[dKey].status) {
            plannerState.logs[dKey].status = 'pending';
          }
          d.setDate(d.getDate() + 1);
        }

        savePlannerData();

        const summaryBox = document.getElementById('cycleSummaryBox');
        const summaryText = document.getElementById('cycleSummaryText');
        if (summaryBox && summaryText) {
          summaryBox.classList.remove('hidden');
          summaryText.textContent = `আলহামদুলিল্লাহ! আপনার লক্ষ্য অনুযায়ী অবশিষ্ট ${toBnNum(stats.remainingPages)} পৃষ্ঠা আগামী ${toBnNum(targetDays)} দিনে খতম করতে প্রতিদিন গড়ে ${toBnNum(dailyTargetPages)} পৃষ্ঠা (${toBnNum((dailyTargetPages/20).toFixed(1))} পারা) পড়তে হবে।`;
        }

        renderKhatamProgress();
        showToast('রোডম্যাপ সফলভাবে সাজানো হয়েছে!');
      });
    }
'''

# 1. Replace HTML
t2_start = content.find('<!-- TAB 2: Roadmap & Plan -->')
t3_start = content.find('<!-- TAB 3: Quranic Diary & Notes -->')

if t2_start == -1 or t3_start == -1:
    print('ERROR: Tab 2 markers not found in HTML!')
    exit(1)

content_updated = content[:t2_start] + tab2_html.strip() + '\n\n        ' + content[t3_start:]

# 2. Replace JS
js_start = content_updated.find('// TAB 2: Roadmap Generator')
js_end = content_updated.find('// TAB 3: Quranic Diary & Notes')

if js_start == -1 or js_end == -1:
    print('ERROR: Tab 2 markers not found in JS!')
    exit(1)

final_content = content_updated[:js_start] + tab2_js.strip() + '\n\n    ' + content_updated[js_end:]

# Replace em-dashes
final_content = final_content.replace('—', '-')

# Write to docs/reader.html and landing/reader.html
with open('docs/reader.html', 'w', encoding='utf-8') as f:
    f.write(final_content)

with open('landing/reader.html', 'w', encoding='utf-8') as f:
    f.write(final_content)

print('SUCCESS: updated Tab 2 with integer target days and live dynamic calculation')
