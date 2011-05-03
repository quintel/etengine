var I18n = {
  translate:function(pKey) {
    return this.MESSAGES[pKey];
  },
  t:function(pKey) {
    return this.translate(pKey);
  },
  setTranslations:function(messages) {
    this.MESSAGES = messages;
  }
  
}