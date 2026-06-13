/**
 * Life On Graph — 多言語お問い合わせフォーム生成 (Google Apps Script)
 *
 * 構成 (画像準拠):
 *   ページ1: 言語選択 (回答に応じて各言語セクションへ移動)
 *   言語ごとのセクション: お名前 / 種類 / 対象データ / 詳細 / 頻度 / 満足度 / 発生日時
 *     → 回答後は送信 (他言語セクションへ流れない)
 *
 * 使い方:
 *   1. https://script.google.com で新規プロジェクト → このコードを貼り付け。
 *   2. createBranchingForm() を実行 (初回は権限承認)。
 *   3. ログ (表示 → ログ) の Published URL / Edit URL を確認。
 *      ※ 既存 URL を維持したい場合は、対象フォームを開き 拡張機能 → Apps Script から
 *         updateActiveForm() を実行する (冪等な差分更新。重複追加されない)。
 *
 * 対応言語: ja / en / de / es / fr / pt (画像の選択肢順)
 */

const LANGS = ['ja', 'en', 'de', 'es', 'fr', 'pt'];

const LANG_LABELS = {
  ja: '日本語', en: 'English', de: 'Deutsch', es: 'Español', fr: 'Français', pt: 'Português',
};

/** ページ1 (言語選択前) は多言語併記。 */
const PAGE1 = {
  title: 'Life On Graph お問い合わせ / Contact',
  description:
    'Life On Graph に関するお問い合わせ・ご要望・不具合報告はこちらから。\n' +
    'Send your questions, requests or bug reports about Life On Graph. ' +
    'まず言語を選択してください / Please select your language.',
  langQuestion: '言語 / Language',
  thankYou: 'お問い合わせありがとうございました。 / Thank you for contacting us.',
};

/** 各言語セクションの設問文言 (キー → 言語 → 文字列)。 */
const T = {
  sectionTitle: {
    ja: '日本語', en: 'English', de: 'Deutsch', es: 'Español', fr: 'Français', pt: 'Português',
  },
  qName: {
    ja: 'お名前', en: 'Your name', de: 'Name', es: 'Nombre', fr: 'Nom', pt: 'Nome',
  },
  qType: {
    ja: 'お問い合わせの種類', en: 'Type of inquiry', de: 'Art der Anfrage',
    es: 'Tipo de consulta', fr: 'Type de demande', pt: 'Tipo de solicitação',
  },
  typeFeature: {
    ja: '機能に関するご質問', en: 'Question about a feature', de: 'Frage zu einer Funktion',
    es: 'Pregunta sobre una función', fr: 'Question sur une fonctionnalité', pt: 'Dúvida sobre um recurso',
  },
  typeBug: {
    ja: '不具合・エラー報告', en: 'Bug / error report', de: 'Fehler-/Problemmeldung',
    es: 'Informe de error', fr: 'Signalement de bug/erreur', pt: 'Relato de erro',
  },
  typeViz: {
    ja: 'データ可視化に関するご要望', en: 'Request about data visualization',
    de: 'Wunsch zur Datenvisualisierung', es: 'Sugerencia sobre la visualización de datos',
    fr: 'Suggestion sur la visualisation des données', pt: 'Sugestão sobre visualização de dados',
  },
  typeOther: {
    ja: 'その他', en: 'Other', de: 'Sonstiges', es: 'Otro', fr: 'Autre', pt: 'Outro',
  },
  qData: {
    ja: 'お問い合わせ対象のデータ', en: 'Data the inquiry is about', de: 'Betroffene Daten',
    es: 'Datos relacionados con la consulta', fr: 'Données concernées', pt: 'Dados relacionados',
  },
  dataSleep: {
    ja: '睡眠データ', en: 'Sleep data', de: 'Schlafdaten', es: 'Datos de sueño',
    fr: 'Données de sommeil', pt: 'Dados de sono',
  },
  dataHeart: {
    ja: '心拍データ', en: 'Heart rate data', de: 'Herzfrequenzdaten',
    es: 'Datos de frecuencia cardíaca', fr: 'Données de fréquence cardiaque', pt: 'Dados de frequência cardíaca',
  },
  dataSteps: {
    ja: '歩数データ', en: 'Step data', de: 'Schrittdaten', es: 'Datos de pasos',
    fr: 'Données de pas', pt: 'Dados de passos',
  },
  dataSync: {
    ja: 'データの連携・同期', en: 'Data sync (Health Connect)', de: 'Datensynchronisierung',
    es: 'Sincronización de datos', fr: 'Synchronisation des données', pt: 'Sincronização de dados',
  },
  dataUi: {
    ja: 'UI・グラフ表示', en: 'UI / chart display', de: 'UI / Diagrammanzeige',
    es: 'UI / visualización de gráficos', fr: 'UI / affichage des graphiques', pt: 'UI / exibição de gráficos',
  },
  qDetail: {
    ja: '詳細内容(具体的な状況やご要望をご記入ください)',
    en: 'Details (please describe the situation or request)',
    de: 'Details (bitte Situation oder Wunsch beschreiben)',
    es: 'Detalles (describe la situación o la solicitud)',
    fr: 'Détails (décrivez la situation ou la demande)',
    pt: 'Detalhes (descreva a situação ou solicitação)',
  },
  qFreq: {
    ja: '問題が発生している場合、頻度についてお選びください。',
    en: 'If you are experiencing an issue, how often does it occur?',
    de: 'Falls ein Problem auftritt, wie häufig?',
    es: 'Si tienes un problema, ¿con qué frecuencia ocurre?',
    fr: 'En cas de problème, à quelle fréquence se produit-il ?',
    pt: 'Se houver um problema, com que frequência ocorre?',
  },
  freqAlways: {
    ja: '常に発生している', en: 'Always', de: 'Immer', es: 'Siempre', fr: 'Toujours', pt: 'Sempre',
  },
  freqOften: {
    ja: '頻繁に発生する', en: 'Often', de: 'Häufig', es: 'A menudo', fr: 'Souvent', pt: 'Frequentemente',
  },
  freqSometimes: {
    ja: '時々発生する', en: 'Sometimes', de: 'Manchmal', es: 'A veces', fr: 'Parfois', pt: 'Às vezes',
  },
  freqOnce: {
    ja: '一度だけ発生した', en: 'Only once', de: 'Nur einmal', es: 'Solo una vez',
    fr: 'Une seule fois', pt: 'Apenas uma vez',
  },
  qSat: {
    ja: '本アプリケーションの利用体験の満足度を評価してください。',
    en: 'How satisfied are you with your experience using the app?',
    de: 'Wie zufrieden bist du mit der Nutzung der App?',
    es: '¿Qué tan satisfecho estás con tu experiencia con la app?',
    fr: 'Quel est votre niveau de satisfaction avec l’application ?',
    pt: 'Qual o seu nível de satisfação ao usar o app?',
  },
  satLow: { ja: '低い', en: 'Low', de: 'Niedrig', es: 'Bajo', fr: 'Faible', pt: 'Baixo' },
  satHigh: { ja: '高い', en: 'High', de: 'Hoch', es: 'Alto', fr: 'Élevé', pt: 'Alto' },
  qDateTime: {
    ja: '可能であれば、問題の発生日時をご記入ください。',
    en: 'If possible, when did the issue occur? (date & time)',
    de: 'Wann ist das Problem aufgetreten? (Datum & Uhrzeit, optional)',
    es: 'Si es posible, ¿cuándo ocurrió el problema? (fecha y hora)',
    fr: 'Si possible, quand le problème s’est-il produit ? (date et heure)',
    pt: 'Se possível, quando ocorreu o problema? (data e hora)',
  },
  qVersion: {
    ja: '発生時のアプリのバージョン番号(任意)',
    en: 'App version when it occurred (optional)',
    de: 'App-Version beim Auftreten (optional)',
    es: 'Versión de la app cuando ocurrió (opcional)',
    fr: 'Version de l’app au moment du problème (facultatif)',
    pt: 'Versão do app quando ocorreu (opcional)',
  },
  qVersionHelp: {
    ja: '「設定 → バージョン」で確認できます (例: 1.2.0)。',
    en: 'Found in Settings → Version (e.g. 1.2.0).',
    de: 'Zu finden unter Einstellungen → Version (z. B. 1.2.0).',
    es: 'Disponible en Ajustes → Versión (p. ej. 1.2.0).',
    fr: 'Disponible dans Réglages → Version (ex. 1.2.0).',
    pt: 'Disponível em Configurações → Versão (ex. 1.2.0).',
  },
};

/** 言語選択 → 言語別セクションへ分岐する新規フォームを作成する。 */
function createBranchingForm() {
  const form = FormApp.create('Life On Graph — Contact / お問い合わせ');
  buildBranchingForm(form);
  Logger.log('Published URL: ' + form.getPublishedUrl());
  Logger.log('Edit URL: ' + form.getEditUrl());
  return form;
}

/**
 * 既存フォーム (バインド済み) を **差分更新** する。既存 URL を維持しつつ、再実行しても
 * 設問が重複追加されないよう、いったん全項目を削除してから定義どおりに再構築する (冪等)。
 * フォーム編集画面の 拡張機能 → Apps Script から実行する。
 *
 * 注意: 既に回答収集中の場合、項目の再作成により回答シートの列対応が変わり得る。
 *       本格運用前 (設定中) に実行すること。
 */
function updateActiveForm() {
  const form = FormApp.getActiveForm();
  if (!form) {
    throw new Error('フォームにバインドされていません。フォーム編集画面の 拡張機能 → Apps Script から実行してください。');
  }
  // 破壊的操作の前に現在の構造をログへバックアップ出力する (復元の手がかり)。
  backupActiveForm();
  clearAllItems(form);
  buildBranchingForm(form);
  Logger.log('差分更新しました (重複なし)。Edit URL: ' + form.getEditUrl());
}

/**
 * フォーム内の全項目を削除する (冪等な再構築のため)。
 *
 * 「回答に応じてセクションに移動」などのナビゲーション参照が残ったまま項目を削除すると
 * `Invalid data updating form` になるため、先に全ナビゲーションを解除してから削除する。
 */
function clearAllItems(form) {
  // 1. ナビゲーション参照を解除する。
  form.getItems().forEach(function (item) {
    const type = item.getType();
    try {
      if (type === FormApp.ItemType.MULTIPLE_CHOICE) {
        const mc = item.asMultipleChoiceItem();
        mc.setChoiceValues(mc.getChoices().map(function (c) { return c.getValue(); }));
      } else if (type === FormApp.ItemType.LIST) {
        const li = item.asListItem();
        li.setChoiceValues(li.getChoices().map(function (c) { return c.getValue(); }));
      } else if (type === FormApp.ItemType.PAGE_BREAK) {
        item.asPageBreakItem().setGoToPage(FormApp.PageNavigationType.CONTINUE);
      }
    } catch (e) {
      // 選択肢が空などのケースは無視して次へ。
    }
  });
  // 2. 末尾から削除する。
  const items = form.getItems();
  for (var i = items.length - 1; i >= 0; i--) {
    form.deleteItem(items[i]);
  }
}

/**
 * 現在のフォーム構造 (タイトル・各項目の種別/タイトル/選択肢) を JSON でログ出力する。
 * 破壊的更新の前のバックアップ用。実行ログをコピーして保管しておけば復元の手がかりになる。
 */
function backupActiveForm() {
  const form = FormApp.getActiveForm();
  if (!form) throw new Error('フォームにバインドされていません。');
  const dump = {
    title: form.getTitle(),
    description: form.getDescription(),
    items: form.getItems().map(function (it) {
      const o = { type: String(it.getType()), title: it.getTitle() };
      try {
        if (it.getType() === FormApp.ItemType.MULTIPLE_CHOICE) {
          o.choices = it.asMultipleChoiceItem().getChoices().map(function (c) { return c.getValue(); });
        } else if (it.getType() === FormApp.ItemType.CHECKBOX) {
          o.choices = it.asCheckboxItem().getChoices().map(function (c) { return c.getValue(); });
        } else if (it.getType() === FormApp.ItemType.LIST) {
          o.choices = it.asListItem().getChoices().map(function (c) { return c.getValue(); });
        }
      } catch (e) {}
      return o;
    }),
  };
  Logger.log('--- FORM BACKUP (copy & keep) ---');
  Logger.log(JSON.stringify(dump, null, 2));
}

/** 文言を取得する。欠落 (undefined/空) なら例外。 "質問" のまま残るのを防ぐ。 */
function tx(key, lang) {
  var v = (T[key] || {})[lang];
  if (v === undefined || v === null || v === '') {
    throw new Error('文言が未定義です: ' + key + ' / ' + lang);
  }
  return v;
}

/** フォーム本体を構築する (言語選択 + 各言語セクション)。 */
function buildBranchingForm(form) {
  form.setTitle(PAGE1.title);
  form.setDescription(PAGE1.description);
  form.setConfirmationMessage(PAGE1.thankYou);
  form.setCollectEmail(false);
  form.setProgressBar(false);

  // ページ1: 言語選択 (プルダウン)。移動先は後で設定。タイトルは別行で明示設定する。
  const langItem = form.addListItem();
  langItem.setTitle(PAGE1.langQuestion);
  langItem.setRequired(true);

  // 各言語セクション。
  const sections = {};
  LANGS.forEach(function (lang) {
    const page = form.addPageBreakItem();
    page.setTitle(tx('sectionTitle', lang));
    page.setGoToPage(FormApp.PageNavigationType.SUBMIT); // セクション完了後は送信
    sections[lang] = page;
    buildSectionQuestions(form, lang);
  });

  // 言語選択の各選択肢を対応セクションへ。
  langItem.setChoices(LANGS.map(function (lang) {
    return langItem.createChoice(LANG_LABELS[lang], sections[lang]);
  }));
}

/**
 * 1 言語セクションの設問を追加する (画像準拠)。
 * 各設問は addXxxItem() の戻り値を変数に受け、setTitle を別行で確実に設定する
 * (チェーンの取りこぼしや未定義文言による "質問" 残りを防ぐ)。
 */
function buildSectionQuestions(form, lang) {
  function s(key) { return tx(key, lang); }

  const name = form.addTextItem();
  name.setTitle(s('qName'));
  name.setRequired(true);

  const type = form.addMultipleChoiceItem();
  type.setTitle(s('qType'));
  type.setChoiceValues([s('typeFeature'), s('typeBug'), s('typeViz'), s('typeOther')]);
  type.setRequired(true);

  const data = form.addCheckboxItem();
  data.setTitle(s('qData'));
  data.setChoiceValues([s('dataSleep'), s('dataHeart'), s('dataSteps'), s('dataSync'), s('dataUi')]);
  data.setRequired(true);

  const detail = form.addParagraphTextItem();
  detail.setTitle(s('qDetail'));
  detail.setRequired(true);

  const freq = form.addMultipleChoiceItem();
  freq.setTitle(s('qFreq'));
  freq.setChoiceValues([s('freqAlways'), s('freqOften'), s('freqSometimes'), s('freqOnce')]);
  freq.setRequired(true);

  // 満足度 1〜5 (Apps Script は星評価を作成できないため線形スケールで代替)。
  const sat = form.addScaleItem();
  sat.setTitle(s('qSat'));
  sat.setBounds(1, 5);
  sat.setLabels(s('satLow'), s('satHigh'));
  sat.setRequired(true);

  // 発生時のアプリのバージョン番号 (任意)。
  const version = form.addTextItem();
  version.setTitle(s('qVersion'));
  version.setHelpText(s('qVersionHelp'));
  // 任意項目 (setRequired は呼ばない = 既定の任意)。

  // 発生日時 (任意)。
  const dt = form.addDateTimeItem();
  dt.setTitle(s('qDateTime'));
}
