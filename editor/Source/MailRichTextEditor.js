/*!
 *
 * mailRichTextEditor v0.5.2
 * http://www.zedsaid.com
 *
 * Copyright 2014 Zed Said Studio LLC
 *
 */

var mail_editor = {};

// If we are using iOS or desktop
mail_editor.isUsingiOS = true;

// If the user is draging
mail_editor.isDragging = false;

// The current selection
mail_editor.currentSelection;

// The current editing image
mail_editor.currentEditingImage;

// The current editing link
mail_editor.currentEditingLink;

// The objects that are enabled
mail_editor.enabledItems = {};

// Height of content window, will be set by viewController
mail_editor.contentHeight = 244;

// Sets to true when extra footer gap shows and requires to hide
mail_editor.updateScrollOffset = false;

/**
 * The initializer function that must be called onLoad
 */
mail_editor.init = function() {
    
    $('#mail_editor_content').on('touchend', function(e) {
                                mail_editor.enabledEditingItems(e);
                                var clicked = $(e.target);
                                if (!clicked.hasClass('zs_active')) {
                                $('img').removeClass('zs_active');
                                }
                                });
    
    $(document).on('selectionchange',function(e){
                   mail_editor.calculateEditorHeightWithCaretPosition();
                   mail_editor.setScrollPosition();
                   mail_editor.enabledEditingItems(e);
                   });
    
    $(window).on('scroll', function(e) {
                 mail_editor.updateOffset();
                 });
    
    // Make sure that when we tap anywhere in the document we focus on the editor
    $(window).on('touchmove', function(e) {
                 mail_editor.isDragging = true;
                 mail_editor.updateScrollOffset = true;
                 mail_editor.setScrollPosition();
                 mail_editor.enabledEditingItems(e);
                 });
    $(window).on('touchstart', function(e) {
                 mail_editor.isDragging = false;
                 });
    $(window).on('touchend', function(e) {
                 if (!mail_editor.isDragging && (e.target.id == "mail_editor_footer"||e.target.nodeName.toLowerCase() == "html")) {
                 mail_editor.focusEditor();
                 }
                 });
    
}//end

mail_editor.updateOffset = function() {
    
    if (!mail_editor.updateScrollOffset)
        return;
    
    var offsetY = window.document.body.scrollTop;
    
    var footer = $('#mail_editor_footer');
    
    var maxOffsetY = footer.offset().top - mail_editor.contentHeight;
    
    if (maxOffsetY < 0)
        maxOffsetY = 0;
    
    if (offsetY > maxOffsetY)
    {
        window.scrollTo(0, maxOffsetY);
    }
    
    mail_editor.setScrollPosition();
}

// This will show up in the XCode console as we are able to push this into an NSLog.
mail_editor.debug = function(msg) {
    window.location = 'debug://'+msg;
}


mail_editor.setScrollPosition = function() {
    var position = window.pageYOffset;
    window.location = 'scroll://'+position;
}


mail_editor.setPlaceholder = function(placeholder) {
    
    var editor = $('#mail_editor_content');
    
    //set placeHolder
	editor.attr("placeholder",placeholder);
	
    //set focus			 
	editor.focusout(function(){
        var element = $(this);        
        if (!element.text().trim().length) {
            element.empty();
        }
    });

}

mail_editor.setFooterHeight = function(footerHeight) {
    var footer = $('#mail_editor_footer');
    footer.height(footerHeight + 'px');
}

mail_editor.getCaretYPosition = function() {
    var sel = window.getSelection();
    // Next line is comented to prevent deselecting selection. It looks like work but if there are any issues will appear then uconmment it as well as code above.
    //sel.collapseToStart();
    var range = sel.getRangeAt(0);
    var span = document.createElement('span');// something happening here preventing selection of elements
    range.collapse(false);
    range.insertNode(span);
    var topPosition = span.offsetTop;
    span.parentNode.removeChild(span);
    return topPosition;
}

mail_editor.calculateEditorHeightWithCaretPosition = function() {
    
    var padding = 50;
    var c = mail_editor.getCaretYPosition();
    
    var editor = $('#mail_editor_content');
    
    var offsetY = window.document.body.scrollTop;
    var height = mail_editor.contentHeight;
    
    var newPos = window.pageYOffset;
    
    if (c < offsetY) {
        newPos = c;
    } else if (c > (offsetY + height - padding)) {
        newPos = c - height + padding - 18;
    }
    
    window.scrollTo(0, newPos);
}

mail_editor.backuprange = function(){
    var selection = window.getSelection();
    var range = selection.getRangeAt(0);
    mail_editor.currentSelection = {"startContainer": range.startContainer, "startOffset":range.startOffset,"endContainer":range.endContainer, "endOffset":range.endOffset};
}

mail_editor.setSelectContent = function(){
  //  mail_editor.prepareInsert();
    mail_editor.setBackgroundColor("#CADDEC");
}

mail_editor.restorerange = function(){
    var selection = window.getSelection();
    selection.removeAllRanges();
    var range = document.createRange();
    range.setStart(mail_editor.currentSelection.startContainer, mail_editor.currentSelection.startOffset);
    range.setEnd(mail_editor.currentSelection.endContainer, mail_editor.currentSelection.endOffset);
    selection.addRange(range);
}

mail_editor.clearSelectBackgroundColor = function() {
    
    var selection = window.getSelection();

    if(selection.toString() != "")
    {

        mail_editor.backuprange();

        var range = document.createRange();
        range.setStart(mail_editor.currentSelection.startContainer, mail_editor.currentSelection.startOffset);
        range.setEnd(mail_editor.currentSelection.endContainer, mail_editor.currentSelection.endOffset);
        selection.addRange(range);

        mail_editor.setBackgroundColor("#ffffff");
    }
   
}

mail_editor.getSelectedNode = function() {
    var node,selection;
    if (window.getSelection) {
        selection = getSelection();
        node = selection.anchorNode;
    }
    if (!node && document.selection) {
        selection = document.selection
        var range = selection.getRangeAt ? selection.getRangeAt(0) : selection.createRange();
        node = range.commonAncestorContainer ? range.commonAncestorContainer :
        range.parentElement ? range.parentElement() : range.item(0);
    }
    if (node) {
        return (node.nodeName == "#text" ? node.parentNode : node);
    }
};

mail_editor.setBold = function() {
    
    mail_editor.restorerange();
    document.execCommand('bold', false, null);
    mail_editor.enabledEditingItems();

}

mail_editor.setItalic = function() {
    mail_editor.restorerange();
    document.execCommand('italic', false, null);
    mail_editor.enabledEditingItems();
}

mail_editor.setSubscript = function() {
    document.execCommand('subscript', false, null);
    mail_editor.enabledEditingItems();
}

mail_editor.setSuperscript = function() {
    document.execCommand('superscript', false, null);
    mail_editor.enabledEditingItems();
}

mail_editor.setStrikeThrough = function() {
    document.execCommand('strikeThrough', false, null);
    mail_editor.enabledEditingItems();
}

mail_editor.setUnderline = function() {
    mail_editor.restorerange();
    document.execCommand('underline', false, null);
    mail_editor.enabledEditingItems();
}

mail_editor.setBlockquote = function() {
    var range = document.getSelection().getRangeAt(0);
    formatName = range.commonAncestorContainer.parentElement.nodeName === 'BLOCKQUOTE'
    || range.commonAncestorContainer.nodeName === 'BLOCKQUOTE' ? '<P>' : '<BLOCKQUOTE>';
    document.execCommand('formatBlock', false, formatName)
    mail_editor.enabledEditingItems();
}

mail_editor.removeFormating = function() {
    document.execCommand('removeFormat', false, null);
    mail_editor.enabledEditingItems();
}

mail_editor.setHorizontalRule = function() {
    document.execCommand('insertHorizontalRule', false, null);
    mail_editor.enabledEditingItems();
}

mail_editor.setHeading = function(size) {
    mail_editor.restorerange();
    var current_selection = $(mail_editor.getSelectedNode());
    var t = current_selection.prop("tagName").toLowerCase();
    var is_heading = (t == 'h1' || t == 'h2' || t == 'h3' || t == 'h4' || t == 'h5' || t == 'h6');
//    if (is_heading && heading == t) {
//        var c = current_selection.html();
//        current_selection.replaceWith(c);
//    } else {
    document.execCommand("styleWithCSS", null, true);
    document.execCommand('fontSize', false, size);
    document.execCommand("styleWithCSS", null, false);
   // }
    
    mail_editor.enabledEditingItems();
}

mail_editor.setParagraph = function() {
    var current_selection = $(mail_editor.getSelectedNode());
    var t = current_selection.prop("tagName").toLowerCase();
    var is_paragraph = (t == 'p');
    if (is_paragraph) {
        var c = current_selection.html();
        current_selection.replaceWith(c);
    } else {
        document.execCommand('formatBlock', false, '<p>');
    }
    
    mail_editor.enabledEditingItems();
}

// Need way to remove formatBlock
console.log('WARNING: We need a way to remove formatBlock items');

mail_editor.undo = function() {
    document.execCommand('undo', false, null);
    mail_editor.enabledEditingItems();
}

mail_editor.redo = function() {
    document.execCommand('redo', false, null);
    mail_editor.enabledEditingItems();
}

mail_editor.setOrderedList = function() {
    document.execCommand('insertOrderedList', false, null);
    mail_editor.enabledEditingItems();
}

mail_editor.setUnorderedList = function() {
    document.execCommand('insertUnorderedList', false, null);
    mail_editor.enabledEditingItems();
}

mail_editor.setJustifyCenter = function() {
    document.execCommand('justifyCenter', false, null);
    mail_editor.enabledEditingItems();
}

mail_editor.setJustifyFull = function() {
    document.execCommand('justifyFull', false, null);
    mail_editor.enabledEditingItems();
}

mail_editor.setJustifyLeft = function() {
    document.execCommand('justifyLeft', false, null);
    mail_editor.enabledEditingItems();
}

mail_editor.setJustifyRight = function() {
    document.execCommand('justifyRight', false, null);
    mail_editor.enabledEditingItems();
}

mail_editor.setIndent = function() {
    document.execCommand('indent', false, null);
    mail_editor.enabledEditingItems();
}

mail_editor.setOutdent = function() {
    document.execCommand('outdent', false, null);
    mail_editor.enabledEditingItems();
}

mail_editor.setFontFamily = function(fontFamily) {

	mail_editor.restorerange();
	document.execCommand("styleWithCSS", null, true);
	document.execCommand("fontName", false, fontFamily);
	document.execCommand("styleWithCSS", null, false);
	mail_editor.enabledEditingItems();
		
}

mail_editor.setTextColor = function(color) {
    mail_editor.restorerange();
    document.execCommand("styleWithCSS", null, true);
    document.execCommand('foreColor', false, color);
    document.execCommand("styleWithCSS", null, false);
    mail_editor.enabledEditingItems();
    // document.execCommand("removeFormat", false, "foreColor"); // Removes just foreColor
	
}

mail_editor.setBackgroundColor = function(color) {
    mail_editor.restorerange();
    document.execCommand("styleWithCSS", null, true);
    document.execCommand('hiliteColor', false, color);
    document.execCommand("styleWithCSS", null, false);
    mail_editor.enabledEditingItems();
}

// Needs addClass method

mail_editor.insertLink = function(url, title) {
    
    mail_editor.restorerange();
    var sel = document.getSelection();
    console.log(sel);
    if (sel.toString().length != 0) {
        if (sel.rangeCount) {
            
            var el = document.createElement("a");
            el.setAttribute("href", url);
            el.setAttribute("title", title);
            
            var range = sel.getRangeAt(0).cloneRange();
            range.surroundContents(el);
            sel.removeAllRanges();
            sel.addRange(range);
        }
    }
    else
    {
        document.execCommand("insertHTML",false,"<a href='"+url+"'>"+title+"</a>");
    }
    
    mail_editor.enabledEditingItems();
}

mail_editor.updateLink = function(url, title) {
    
    mail_editor.restorerange();
    
    if (mail_editor.currentEditingLink) {
        var c = mail_editor.currentEditingLink;
        c.attr('href', url);
        c.attr('title', title);
    }
    mail_editor.enabledEditingItems();
    
}//end

mail_editor.updateImage = function(url, alt) {
    
    mail_editor.restorerange();
    
    if (mail_editor.currentEditingImage) {
        var c = mail_editor.currentEditingImage;
        c.attr('src', url);
        c.attr('alt', alt);
    }
    mail_editor.enabledEditingItems();
    
}//end

mail_editor.updateImageBase64String = function(imageBase64String, alt) {
    
    mail_editor.restorerange();
    
    if (mail_editor.currentEditingImage) {
        var c = mail_editor.currentEditingImage;
        var src = 'data:image/jpeg;base64,' + imageBase64String;
        c.attr('src', src);
        c.attr('alt', alt);
    }
    mail_editor.enabledEditingItems();
    
}//end


mail_editor.unlink = function() {
    
    if (mail_editor.currentEditingLink) {
        var c = mail_editor.currentEditingLink;
        c.contents().unwrap();
    }
    mail_editor.enabledEditingItems();
}

mail_editor.quickLink = function() {
    
    var sel = document.getSelection();
    var link_url = "";
    var test = new String(sel);
    var mailregexp = new RegExp("^(.+)(\@)(.+)$", "gi");
    if (test.search(mailregexp) == -1) {
        checkhttplink = new RegExp("^http\:\/\/", "gi");
        if (test.search(checkhttplink) == -1) {
            checkanchorlink = new RegExp("^\#", "gi");
            if (test.search(checkanchorlink) == -1) {
                link_url = "http://" + sel;
            } else {
                link_url = sel;
            }
        } else {
            link_url = sel;
        }
    } else {
        checkmaillink = new RegExp("^mailto\:", "gi");
        if (test.search(checkmaillink) == -1) {
            link_url = "mailto:" + sel;
        } else {
            link_url = sel;
        }
    }
    
    var html_code = '<a href="' + link_url + '">' + sel + '</a>';
    mail_editor.insertHTML(html_code);
    
}

mail_editor.prepareInsert = function() {
    mail_editor.backuprange();
}

mail_editor.insertImage = function(url, alt) {
    mail_editor.restorerange();
    var html = '<img src="'+url+'" alt="'+alt+'" />';
    mail_editor.insertHTML(html);
    mail_editor.enabledEditingItems();
}

mail_editor.insertImageBase64String = function(imageBase64String, alt) {
    mail_editor.restorerange();
    var html = '<img src="data:image/jpeg;base64,'+imageBase64String+'" alt="'+alt+'" />';
    mail_editor.insertHTML(html);
    mail_editor.enabledEditingItems();
}

mail_editor.setHTML = function(html) {
    var editor = $('#mail_editor_content');
    editor.html(html);
}

mail_editor.insertHTML = function(html) {
    document.execCommand('insertHTML', false, html);
    mail_editor.enabledEditingItems();
}

mail_editor.getHTML = function() {
    
    // Images
    var img = $('img');
    if (img.length != 0) {
        $('img').removeClass('zs_active');
        $('img').each(function(index, e) {
                      var image = $(this);
                      var zs_class = image.attr('class');
                      if (typeof(zs_class) != "undefined") {
                      if (zs_class == '') {
                      image.removeAttr('class');
                      }
                      }
                      });
    }
    
    // Blockquote
    var bq = $('blockquote');
    if (bq.length != 0) {
        bq.each(function() {
                var b = $(this);
                if (b.css('border').indexOf('none') != -1) {
                b.css({'border': ''});
                }
                if (b.css('padding').indexOf('0px') != -1) {
                b.css({'padding': ''});
                }
                });
    }
    
    // Get the contents
    var h = document.getElementById("mail_editor_content").innerHTML;
    
    return h;
}

mail_editor.getText = function() {
    return $('#mail_editor_content').text();
}

mail_editor.isCommandEnabled = function(commandName) {
    return document.queryCommandState(commandName);
}

mail_editor.enabledEditingItems = function(e) {
    
    console.log('enabledEditingItems');
    var items = [];
    if (mail_editor.isCommandEnabled('bold')) {
        items.push('bold');
    }
    if (mail_editor.isCommandEnabled('italic')) {
        items.push('italic');
    }
    if (mail_editor.isCommandEnabled('subscript')) {
        items.push('subscript');
    }
    if (mail_editor.isCommandEnabled('superscript')) {
        items.push('superscript');
    }
    if (mail_editor.isCommandEnabled('strikeThrough')) {
        items.push('strikeThrough');
    }
    if (mail_editor.isCommandEnabled('underline')) {
        items.push('underline');
    }
    if (mail_editor.isCommandEnabled('insertOrderedList')) {
        items.push('orderedList');
    }
    if (mail_editor.isCommandEnabled('insertUnorderedList')) {
        items.push('unorderedList');
    }
    if (mail_editor.isCommandEnabled('justifyCenter')) {
        items.push('justifyCenter');
    }
    if (mail_editor.isCommandEnabled('justifyFull')) {
        items.push('justifyFull');
    }
    if (mail_editor.isCommandEnabled('justifyLeft')) {
        items.push('justifyLeft');
    }
    if (mail_editor.isCommandEnabled('justifyRight')) {
        items.push('justifyRight');
    }
    if (mail_editor.isCommandEnabled('insertHorizontalRule')) {
        items.push('horizontalRule');
    }
    var formatBlock = document.queryCommandValue('formatBlock');
    if (formatBlock.length > 0) {
        items.push(formatBlock);
    }
    // Images
    $('img').bind('touchstart', function(e) {
                  $('img').removeClass('zs_active');
                  $(this).addClass('zs_active');
                  });
    
    // Use jQuery to figure out those that are not supported
    if (typeof(e) != "undefined") {
        
        // The target element
        var s = mail_editor.getSelectedNode();
        var t = $(s);
        var nodeName = e.target.nodeName.toLowerCase();
        
        // Background Color
        var bgColor = t.css('backgroundColor');
        if (bgColor.length != 0 && bgColor != 'rgba(0, 0, 0, 0)' && bgColor != 'rgb(0, 0, 0)' && bgColor != 'transparent') {
            items.push('backgroundColor');
        }
        // Text Color
        var textColor = t.css('color');
        if (textColor.length != 0 && textColor != 'rgba(0, 0, 0, 0)' && textColor != 'rgb(0, 0, 0)' && textColor != 'transparent') {
            items.push('textColor');
        }
		
		//Fonts
		var font = t.css('font-family');
		if (font.length != 0 && font != 'Arial, Helvetica, sans-serif') {
			items.push('fonts');	
		}
		
        // Link
        if (nodeName == 'a') {
            mail_editor.currentEditingLink = t;
            var title = t.attr('title');
            items.push('link:'+t.attr('href'));
            if (t.attr('title') !== undefined) {
                items.push('link-title:'+t.attr('title'));
            }
            
        } else {
            mail_editor.currentEditingLink = null;
        }
        // Blockquote
        if (nodeName == 'blockquote') {
            items.push('indent');
        }
        // Image
        if (nodeName == 'img') {
            mail_editor.currentEditingImage = t;
            items.push('image:'+t.attr('src'));
            if (t.attr('alt') !== undefined) {
                items.push('image-alt:'+t.attr('alt'));
            }
            
        } else {
            mail_editor.currentEditingImage = null;
        }
        
    }
    
    if (items.length > 0) {
        if (mail_editor.isUsingiOS) {
            //window.location = "mail-callback/"+items.join(',');
            window.location = "callback://0/"+items.join(',');
        } else {
            console.log("callback://"+items.join(','));
        }
    } else {
        if (mail_editor.isUsingiOS) {
            window.location = "mail-callback/";
        } else {
            console.log("callback://");
        }
    }
}

mail_editor.clearRecord = function(stapNum) {
    var selection = window.getSelection();
    
    if(selection.toString() != "")
    {
        var i = 0;
        while(i < stapNum)
        {
            mail_editor.undo();
            i++;
        }
    }
}

mail_editor.focusEditor = function() {
    
    // the following was taken from http://stackoverflow.com/questions/1125292/how-to-move-cursor-to-end-of-contenteditable-entity/3866442#3866442
    // and ensures we move the cursor to the end of the editor
 //   mail_editor.clearSelectBackgroundColor()
    
    var editor = $('#mail_editor_content');
    var range = document.createRange();
    range.selectNodeContents(editor.get(0));
    range.collapse(false);
    var selection = window.getSelection();
    selection.removeAllRanges();
    selection.addRange(range);
    editor.focus();
}


mail_editor.focus = function() {
    
    var editor = $('#mail_editor_content');
    editor.focus();

}




mail_editor.blurEditor = function() {
//    $('#mail_editor_content').blur();
    var editor = $('#mail_editor_content');
    
    editor.blur();
}

mail_editor.setCustomCSS = function(customCSS) {
    
    document.getElementsByTagName('style')[0].innerHTML=customCSS;
    
    //set focus
    /*editor.focusout(function(){
                    var element = $(this);
                    if (!element.text().trim().length) {
                    element.empty();
                    }
                    });*/
    
    
    
}

//end
