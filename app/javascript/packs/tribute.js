var Tribute = require("tributejs")
var Trix = require("trix")
var tribute, trix

$(document).on("trix-initialize", handleUserTagging)
function handleUserTagging(e) {
    if (tribute && trix) {
        tribute.detach(trix)
    }
    trix = e.target
    
    var users = $(trix).data("user-mention")
    if (!users) return
    
    var editor = trix.editor
    tribute = new Tribute({
        values: users.map(user => ({value: user.name || user.email, sgid: user.attachable_sgid })),
        lookup: "value",
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
            sgid: user.sgid,
            content: "<span class='text-primary'>"+user.value+"</span>&nbsp;",
            contentType: "text/html",
        })
        editor.insertAttachment(attachment)
    })
}