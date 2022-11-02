var Tribute = require("tributejs")
var Trix = require("trix")
var tribute, trix

$(document).on("trix-initialize", handleUserTagging)
function handleUserTagging(e) {
    console.log(e)
    if (tribute && trix) {
        tribute.detach(trix)
    }
    trix = document.querySelector('trix-editor')
    if (!trix) return
    
    var users = $(trix).data("user-tagging")
    if (!users) return
    
    var editor = trix.editor
    tribute = new Tribute({
        values: users,
        lookup: "name",
        allowSpaces: true,
    });
    tribute.attach(trix)
    tribute.range.pasteHtml = function (html, startPos, endPos) {
        var position = editor.getPosition()
        editor.setSelectedRange([position - endPos + startPos, position + 1])
        editor.deleteInDirection("backward")
    }
    trix.addEventListener("tribute-replaced", function (e) {
        var user = e.detail.item.original
        var attachment = new Trix.Attachment({
            sgid: user.attachable_sgid,
            content: "<span class='text-primary'>"+user.name+"</span>",
            contentType: "text/html",
        })
        editor.insertAttachment(attachment)
    })
}