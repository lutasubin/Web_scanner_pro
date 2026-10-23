package com.example.web_scanner_pro.web

object WebMobileLayout {
    fun install(scale: Float, expandedWidth: Float): String = """
        (function(){
          var STYLE_ID='web-scanner-mobile-layout';
          var style=document.getElementById(STYLE_ID);
          if(!style){
            style=document.createElement('style');
            style.id=STYLE_ID;
            document.head.appendChild(style);
          }
          style.textContent=`
            html,body,*{overscroll-behavior-x:none!important;box-sizing:border-box;}
            html,body{overflow-x:hidden!important;}
            *::-webkit-scrollbar:horizontal{height:0!important;display:none!important;}
            [data-web-scanner-root]{display:flex!important;width:100%!important;min-width:100%!important;max-width:100%!important;overflow:hidden!important;}
            [data-web-scanner-content]{display:flex!important;left:56px!important;right:0!important;width:calc(100% - 56px)!important;min-width:calc(100% - 56px)!important;max-width:calc(100% - 56px)!important;flex:0 0 calc(100% - 56px)!important;overflow:hidden!important;}
            [data-web-scanner-pane='nav']{display:flex!important;visibility:visible!important;width:56px!important;min-width:56px!important;max-width:56px!important;flex:0 0 56px!important;transform:none!important;}
            [data-web-scanner-pane='list']{width:calc(100% - 56px)!important;min-width:calc(100% - 56px)!important;max-width:calc(100% - 56px)!important;flex:0 0 calc(100% - 56px)!important;overflow:hidden!important;}
            [data-web-scanner-content] [data-web-scanner-pane='list']{width:100%!important;min-width:100%!important;max-width:100%!important;flex:0 0 100%!important;margin-left:0!important;}
            [data-web-scanner-pane='detail']{width:100%!important;min-width:100%!important;max-width:100%!important;flex:0 0 100%!important;overflow:hidden!important;}
            body.web-scanner-list [data-web-scanner-pane='detail'],
            body.web-scanner-list [data-web-scanner-pane='aux'],
            body.web-scanner-detail [data-web-scanner-pane='nav'],
            body.web-scanner-detail [data-web-scanner-pane='list']{display:none!important;}
            body.web-scanner-list [data-web-scanner-pane='nav'],
            body.web-scanner-list [data-web-scanner-pane='list'],
            body.web-scanner-detail [data-web-scanner-pane='detail']{display:flex!important;visibility:visible!important;transform:none!important;}
            body.web-scanner-detail [data-web-scanner-content]{left:0!important;width:100%!important;min-width:100%!important;max-width:100%!important;flex-basis:100%!important;}
            body.web-scanner-list #pane-side,
            body.web-scanner-detail #main{width:100%!important;min-width:100%!important;max-width:100%!important;overflow:hidden!important;}
            body.web-scanner-list [data-web-scanner-pane='list']>header,
            body.web-scanner-list #side{width:100%!important;min-width:100%!important;max-width:100%!important;}
            body.web-scanner-detail .focusable-list-item{padding-left:12px!important;padding-right:12px!important;}
            body.web-scanner-detail .focusable-list-item>div{max-width:100%!important;}
            body.web-scanner-detail [data-testid='conversation-header'] button[aria-label^='Trình duyệt của bạn không hỗ trợ'],
            body.web-scanner-detail [data-testid='conversation-header'] button[aria-label='Tìm kiếm']{display:none!important;}
            body.web-scanner-detail [data-testid='drawer-left']{display:none!important;}
            body.web-scanner-detail [data-testid='drawer-middle']{width:100%!important;min-width:100%!important;max-width:100%!important;flex:1 1 100%!important;}
            body.web-scanner-detail [data-testid='drawer-right'],
            body.web-scanner-detail [data-testid='drawer-fullscreen']{left:0!important;right:0!important;width:100%!important;min-width:100%!important;max-width:100%!important;}
            body.web-scanner-detail [data-testid='filter-button'],
            body.web-scanner-detail [data-testid='shape-button'],
            body.web-scanner-detail [data-testid='blur-button'],
            body.web-scanner-detail [data-testid='emoji-button'],
            body.web-scanner-detail [data-testid='wds-ic-hd-settings'],
            body.web-scanner-detail button:has([data-testid='filter-button']),
            body.web-scanner-detail button:has([data-testid='shape-button']),
            body.web-scanner-detail button:has([data-testid='blur-button']),
            body.web-scanner-detail button:has([data-testid='emoji-button']),
            body.web-scanner-detail button:has([data-testid='wds-ic-hd-settings']),
            body.web-scanner-detail [data-testid='media-editor-copy-button']{display:none!important;}
            body.web-scanner-detail [data-web-scanner-editor-secondary]{display:none!important;}
            body.web-scanner-detail [data-web-scanner-editor-toolbar]{height:50px!important;min-height:50px!important;padding:5px 8px!important;gap:4px!important;}
            body.web-scanner-detail [data-web-scanner-editor-toolbar]>div{min-width:0!important;justify-content:space-evenly!important;flex:1 1 auto!important;}
            body.web-scanner-detail [data-testid='crop-rotate-button'],
            body.web-scanner-detail [data-testid='paint-button'],
            body.web-scanner-detail [data-testid='text-button'],
            body.web-scanner-detail [data-testid='sticker-button'],
            body.web-scanner-detail button:has([data-testid='crop-rotate-button']),
            body.web-scanner-detail button:has([data-testid='paint-button']),
            body.web-scanner-detail button:has([data-testid='text-button']),
            body.web-scanner-detail button:has([data-testid='sticker-button']){width:38px!important;height:38px!important;}
            body.web-scanner-detail [data-testid='media-editor-canvas']{width:min(84vw,344px)!important;height:min(84vw,344px)!important;max-width:344px!important;max-height:344px!important;}
            body.web-scanner-detail [data-testid='media-editor-canvas']>img,
            body.web-scanner-detail [data-testid='media-editor-canvas']>canvas{width:100%!important;height:100%!important;max-width:100%!important;max-height:100%!important;object-fit:contain!important;}
            body.web-scanner-detail [data-web-scanner-caption-row]{width:auto!important;min-width:0!important;max-width:none!important;flex:1 1 auto!important;margin:0 8px 0 12px!important;}
            body.web-scanner-detail [data-web-scanner-caption-shell]{width:auto!important;min-width:0!important;max-width:none!important;flex:1 1 auto!important;}
            body.web-scanner-detail [data-testid='media-caption-input-container']{width:100%!important;min-width:0!important;max-width:none!important;}
            body.web-scanner-detail [data-testid='drawer-middle'] span:has(>div>div>[data-testid='wds-ic-send-filled']),
            body.web-scanner-detail [data-testid='drawer-middle'] span:has(>div>div>[data-testid='wds-ic-send-filled'])>div,
            body.web-scanner-detail [data-testid='drawer-middle'] span:has(>div>div>[data-testid='wds-ic-send-filled'])>div>div{width:48px!important;height:48px!important;}
            body.web-scanner-detail [data-testid='wds-ic-send-filled']{width:24px!important;height:24px!important;}
            body.web-scanner-detail button[aria-label='Thêm file']{width:48px!important;height:48px!important;}
            [data-web-scanner-modal-host]{overflow:visible!important;transform:none!important;contain:none!important;clip-path:none!important;filter:none!important;perspective:none!important;}
            [data-web-scanner-modal-layer]{position:fixed!important;inset:0!important;z-index:2147483000!important;width:var(--web-scanner-vw)!important;min-width:0!important;max-width:var(--web-scanner-vw)!important;height:var(--web-scanner-vh)!important;min-height:0!important;max-height:var(--web-scanner-vh)!important;display:flex!important;visibility:visible!important;opacity:1!important;align-items:center!important;justify-content:center!important;padding:max(12px,env(safe-area-inset-top)) max(12px,env(safe-area-inset-right)) max(12px,env(safe-area-inset-bottom)) max(12px,env(safe-area-inset-left))!important;overflow:hidden!important;transform:none!important;box-sizing:border-box!important;}
            [data-web-scanner-modal-self]{position:fixed!important;z-index:2147483001!important;inset:auto!important;left:calc(var(--web-scanner-vw) / 2)!important;top:calc(var(--web-scanner-vh) / 2)!important;transform:translate(-50%,-50%)!important;width:min(calc(var(--web-scanner-vw) - 24px),360px)!important;min-width:0!important;max-width:calc(var(--web-scanner-vw) - 24px)!important;height:auto!important;min-height:0!important;max-height:calc(var(--web-scanner-vh) - 24px)!important;margin:0!important;display:flex!important;visibility:visible!important;opacity:1!important;flex-direction:column!important;overflow:auto!important;overscroll-behavior:contain!important;box-sizing:border-box!important;}
            [data-web-scanner-modal-card]{position:relative!important;inset:auto!important;transform:none!important;width:min(calc(var(--web-scanner-vw) - 24px),360px)!important;min-width:0!important;max-width:calc(var(--web-scanner-vw) - 24px)!important;height:auto!important;min-height:0!important;max-height:calc(var(--web-scanner-vh) - 24px)!important;margin:auto!important;display:flex!important;visibility:visible!important;opacity:1!important;flex-direction:column!important;overflow:auto!important;overscroll-behavior:contain!important;border-radius:14px!important;box-sizing:border-box!important;}
            [data-web-scanner-proxied]{visibility:hidden!important;pointer-events:none!important;}
            #web-scanner-dialog-proxy{position:fixed!important;inset:0!important;z-index:2147483646!important;width:var(--web-scanner-vw)!important;height:var(--web-scanner-vh)!important;display:flex!important;align-items:center!important;justify-content:center!important;padding:max(12px,env(safe-area-inset-top)) max(12px,env(safe-area-inset-right)) max(12px,env(safe-area-inset-bottom)) max(12px,env(safe-area-inset-left))!important;overflow:hidden!important;pointer-events:none!important;box-sizing:border-box!important;}
            [data-web-scanner-proxy-card]{position:relative!important;inset:auto!important;z-index:2147483647!important;transform:none!important;width:min(calc(var(--web-scanner-vw) - 24px),360px)!important;min-width:0!important;max-width:calc(var(--web-scanner-vw) - 24px)!important;height:auto!important;min-height:0!important;max-height:calc(var(--web-scanner-vh) - 24px)!important;margin:auto!important;display:flex!important;visibility:visible!important;opacity:1!important;flex-direction:column!important;overflow:auto!important;overscroll-behavior:contain!important;border-radius:14px!important;background:var(--modal-background,var(--panel-background,#fff))!important;color:var(--primary,#111)!important;box-shadow:0 12px 36px rgba(0,0,0,.32)!important;pointer-events:auto!important;box-sizing:border-box!important;}
            [data-web-scanner-proxy-card]>*{min-width:0!important;max-width:100%!important;}
            [data-web-scanner-proxy-card]>div{height:auto!important;min-height:0!important;max-height:calc(var(--web-scanner-vh) - 24px)!important;justify-content:flex-start!important;flex:0 1 auto!important;}
            [data-web-scanner-proxy-card] [data-web-scanner-modal-actions]{position:relative!important;margin-top:20px!important;}
            [data-web-scanner-proxy-card] button,[data-web-scanner-proxy-card] [role='button']{min-height:44px!important;max-width:100%!important;}
            [data-web-scanner-modal-card]>*,[data-web-scanner-modal-self]>*{min-width:0!important;max-width:100%!important;}
            [data-web-scanner-modal-card] h1,[data-web-scanner-modal-card] h2,[data-web-scanner-modal-card] h3,[data-web-scanner-modal-card] p,[data-web-scanner-modal-card] span,[data-web-scanner-modal-self] h1,[data-web-scanner-modal-self] h2,[data-web-scanner-modal-self] h3,[data-web-scanner-modal-self] p,[data-web-scanner-modal-self] span{max-width:100%!important;overflow-wrap:anywhere!important;white-space:normal!important;}
            [data-web-scanner-modal-card] img,[data-web-scanner-modal-card] video,[data-web-scanner-modal-self] img,[data-web-scanner-modal-self] video{max-width:100%!important;max-height:calc(var(--web-scanner-vh) - 144px)!important;object-fit:contain!important;}
            [data-web-scanner-modal-actions]{position:sticky!important;left:0!important;right:0!important;bottom:0!important;z-index:2!important;flex:0 0 auto!important;min-width:0!important;max-width:100%!important;display:flex!important;flex-wrap:wrap!important;justify-content:flex-end!important;gap:8px!important;padding-bottom:max(8px,env(safe-area-inset-bottom))!important;background:inherit!important;}
            [data-web-scanner-modal-actions] button,[data-web-scanner-modal-actions] [role='button']{min-height:44px!important;max-width:100%!important;white-space:normal!important;}
            [data-web-scanner-floating]{z-index:2147483002!important;max-width:calc(var(--web-scanner-vw) - 16px)!important;max-height:calc(var(--web-scanner-vh) - 16px)!important;overflow:auto!important;overscroll-behavior:contain!important;box-sizing:border-box!important;}
            #web-scanner-chat-back{display:flex!important;align-items:center!important;justify-content:center!important;width:44px!important;min-width:44px!important;height:44px!important;margin:0 2px 0 0!important;padding:0!important;border:0!important;background:transparent!important;color:#111!important;font:400 34px/1 sans-serif!important;cursor:pointer!important;}
          `;
          document.documentElement.style.zoom='$scale';
          document.documentElement.style.width='${expandedWidth}%';
          document.documentElement.style.overflowX='hidden';
          document.body.style.overflowX='hidden';

          var VERSION=13;
          if(window.__webScannerMobileLayout&&window.__webScannerMobileLayout.version===VERSION){
            window.__webScannerMobileLayout.refresh();
            return 'updated';
          }
          if(window.__webScannerMobileObserver){
            window.__webScannerMobileObserver.disconnect();
            window.__webScannerMobileObserver=null;
          }
          if(window.__webScannerViewportCleanup)window.__webScannerViewportCleanup();

          function directChild(ancestor,node){
            var child=node;
            while(child&&child.parentElement!==ancestor)child=child.parentElement;
            return child;
          }

          function commonAncestor(first,second){
            var seen=new Set(),node=first;
            while(node){seen.add(node);node=node.parentElement;}
            node=second;
            while(node&&!seen.has(node))node=node.parentElement;
            return node;
          }

          var api={version:VERSION,mode:'list',root:null,content:null,nav:null,list:null,detail:null,paneNode:null,mainNode:null};

          api.updateViewport=function(){
            var viewport=window.visualViewport;
            var width=(viewport?viewport.width:window.innerWidth)/$scale;
            var height=(viewport?viewport.height:window.innerHeight)/$scale;
            document.documentElement.style.setProperty('--web-scanner-vw',Math.max(80,width)+'px');
            document.documentElement.style.setProperty('--web-scanner-vh',Math.max(80,height)+'px');
          };

          api.removeDialogProxy=function(){
            var proxy=document.getElementById('web-scanner-dialog-proxy');
            if(proxy&&proxy.__source)proxy.__source.removeAttribute('data-web-scanner-proxied');
            if(proxy)proxy.remove();
          };

          api.syncDialogProxy=function(){
            function destructiveText(node){
              var text=(node.textContent||'').normalize('NFD').replace(/[\u0300-\u036f]/g,'')
                .replace(/\s+/g,' ').trim().toLowerCase();
              return /(^|\s)xoa(\s|$)|(^|\s)delete(\s|$)/.test(text);
            }
            var candidates=Array.from(document.querySelectorAll("[data-testid='confirm-popup'],[data-animate-modal-popup='true']"));
            var sources=candidates.filter(function(node){
              if(node.closest('#web-scanner-dialog-proxy'))return false;
              if(!node.isConnected)return false;
              return destructiveText(node);
            });
            Array.from(document.querySelectorAll("[role='dialog'],[aria-modal='true']")).forEach(function(dialog){
              if(dialog.closest('#web-scanner-dialog-proxy'))return;
              var style=getComputedStyle(dialog),rect=dialog.getBoundingClientRect();
              if(style.display==='none'||style.visibility==='hidden'||rect.width<2||rect.height<2)return;
              Array.from(dialog.children).forEach(function(child){
                var box=child.getBoundingClientRect();
                if(box.width>80&&box.height>40&&destructiveText(child)&&
                   child.querySelectorAll("button,[role='button']").length>=2)sources.push(child);
              });
            });
            sources=Array.from(new Set(sources)).sort(function(left,right){
              var a=left.getBoundingClientRect(),b=right.getBoundingClientRect();
              return a.width*a.height-b.width*b.height;
            });
            var source=sources[0];
            var current=document.getElementById('web-scanner-dialog-proxy');
            if(!source){api.removeDialogProxy();return;}
            var signature=(source.textContent||'').length+':'+source.querySelectorAll("button,[role='button']").length;
            if(current&&current.__source===source&&current.__signature===signature)return;
            api.removeDialogProxy();

            var proxy=document.createElement('div');
            proxy.id='web-scanner-dialog-proxy';
            proxy.setAttribute('aria-live','polite');
            var clone=source.cloneNode(true);
            clone.removeAttribute('id');
            clone.removeAttribute('data-web-scanner-proxied');
            clone.removeAttribute('data-web-scanner-modal-card');
            clone.setAttribute('data-web-scanner-proxy-card','true');
            Array.from(clone.querySelectorAll('[id]')).forEach(function(node){node.removeAttribute('id');});

            var originals=Array.from(source.querySelectorAll("button,[role='button']"));
            var controls=Array.from(clone.querySelectorAll("button,[role='button']"));
            controls.forEach(function(control,index){
              control.addEventListener('click',function(event){
                event.preventDefault();event.stopPropagation();
                var original=originals[index];
                if(original)original.click();
              });
            });
            source.setAttribute('data-web-scanner-proxied','true');
            proxy.__source=source;
            proxy.__signature=signature;
            proxy.appendChild(clone);
            document.body.appendChild(proxy);
          };

          api.findListRoot=function(pane){
            var branch=pane;
            while(branch&&branch.parentElement&&branch.parentElement!==document.body){
              var parent=branch.parentElement;
              var parentBox=parent.getBoundingClientRect();
              var branchBox=branch.getBoundingClientRect();
              if(parent.children.length>1&&parentBox.height>window.innerHeight*0.55&&
                 parentBox.width>branchBox.width*1.28)return {root:parent,list:branch};
              branch=parent;
            }
            return null;
          };

          api.mark=function(){
            var pane=document.querySelector("#pane-side,[data-testid='chat-list']");
            var main=document.querySelector('#main');
            var root=null,contentBranch=null,navBranch=null,listBranch=null,detailBranch=null;
            var callsList=pane&&pane.closest("[data-testid='drawer-left']");
            var callsDetail=callsList&&callsList.parentElement&&
              callsList.parentElement.querySelector(":scope > [data-testid='drawer-middle']");
            var navigationHeader=Array.from(document.querySelectorAll("[data-testid='chatlist-header']")).find(function(header){
              return header.querySelector("[data-testid='navbar-primary-section']");
            });
            if(!main&&callsList&&callsDetail&&navigationHeader){
              root=commonAncestor(navigationHeader,callsList);
              contentBranch=commonAncestor(callsList,callsDetail);
              navBranch=directChild(root,navigationHeader);
              listBranch=directChild(contentBranch,callsList);
              detailBranch=directChild(contentBranch,callsDetail);
            }else if(pane&&main){
              root=commonAncestor(pane,main);
              if(root&&root!==document.body&&root!==document.documentElement){
                listBranch=directChild(root,pane);
                detailBranch=directChild(root,main);
                if(listBranch===detailBranch){root=null;listBranch=null;detailBranch=null;}
              }
            }
            if(!root&&pane){
              var found=api.findListRoot(pane);
              if(found){root=found.root;listBranch=found.list;}
            }
            if(!root||!listBranch)return false;

            navBranch=navBranch||Array.from(root.children).find(function(child){
              var labels=Array.from(child.querySelectorAll('[aria-label]')).map(function(node){
                return (node.getAttribute('aria-label')||'').toLowerCase();
              });
              var hasChats=labels.some(function(label){return label==='chats'||label.includes('đoạn chat');});
              var hasCalls=labels.some(function(label){return label==='calls'||label.includes('cuộc gọi');});
              var hasStatus=labels.some(function(label){return label==='status'||label.includes('trạng thái');});
              return hasChats&&(hasCalls||hasStatus);
            });

            if(api.root===root&&api.content===contentBranch&&api.nav===navBranch&&api.list===listBranch&&
               api.detail===detailBranch&&root.isConnected&&listBranch.isConnected){
              api.paneNode=pane;api.mainNode=main;
              return true;
            }

            document.querySelectorAll('[data-web-scanner-pane]').forEach(function(node){
              node.removeAttribute('data-web-scanner-pane');
            });
            document.querySelectorAll('[data-web-scanner-root]').forEach(function(node){
              node.removeAttribute('data-web-scanner-root');
            });
            document.querySelectorAll('[data-web-scanner-content]').forEach(function(node){
              node.removeAttribute('data-web-scanner-content');
            });
            root.setAttribute('data-web-scanner-root','true');
            if(contentBranch)contentBranch.setAttribute('data-web-scanner-content','true');
            if(navBranch)navBranch.setAttribute('data-web-scanner-pane','nav');
            listBranch.setAttribute('data-web-scanner-pane','list');
            if(detailBranch)detailBranch.setAttribute('data-web-scanner-pane','detail');
            Array.from(root.children).forEach(function(child){
              if(child===contentBranch||child===navBranch||child===listBranch||child===detailBranch)return;
              var box=child.getBoundingClientRect();
              if(box.height>window.innerHeight*0.55)child.setAttribute('data-web-scanner-pane','aux');
            });
            api.root=root;api.content=contentBranch;api.nav=navBranch;
            api.list=listBranch;api.detail=detailBranch;
            api.paneNode=pane;api.mainNode=main;
            return true;
          };

          api.addBackButton=function(){
            if(api.mode!=='detail')return;
            var main=document.querySelector('#main');
            var header=main&&main.querySelector('header');
            if(!header||header.querySelector('#web-scanner-chat-back'))return;
            var button=document.createElement('button');
            button.id='web-scanner-chat-back';
            button.type='button';
            button.textContent='‹';
            button.setAttribute('aria-label','Back to chats');
            button.addEventListener('click',function(event){
              event.preventDefault();event.stopPropagation();api.showList();
            });
            header.insertBefore(button,header.firstChild);
          };

          api.markMobileSurfaces=function(){
            var crop=document.querySelector("[data-testid='crop-rotate-button']");
            var tools=crop&&crop.parentElement;
            var toolbar=tools&&tools.parentElement;
            if(toolbar){
              toolbar.setAttribute('data-web-scanner-editor-toolbar','true');
              Array.from(toolbar.querySelectorAll('button')).forEach(function(button){
                var label=button.getAttribute('aria-label');
                if(!label||label==='Viền'||label==='Border'){
                  var item=tools.contains(button)?directChild(tools,button):directChild(toolbar,button);
                  if(item)item.setAttribute('data-web-scanner-editor-secondary','true');
                }
              });
            }

            var caption=document.querySelector("[data-testid='media-caption-input-container']");
            var captionShell=caption&&caption.parentElement&&caption.parentElement.parentElement;
            var captionRow=captionShell&&captionShell.parentElement;
            if(captionShell)captionShell.setAttribute('data-web-scanner-caption-shell','true');
            if(captionRow)captionRow.setAttribute('data-web-scanner-caption-row','true');

            document.querySelectorAll('[data-web-scanner-modal-host]').forEach(function(node){
              node.removeAttribute('data-web-scanner-modal-host');
            });
            document.querySelectorAll('[data-web-scanner-modal-layer],[data-web-scanner-modal-self],[data-web-scanner-modal-card],[data-web-scanner-modal-actions]').forEach(function(node){
              node.removeAttribute('data-web-scanner-modal-layer');
              node.removeAttribute('data-web-scanner-modal-self');
              node.removeAttribute('data-web-scanner-modal-card');
              node.removeAttribute('data-web-scanner-modal-actions');
            });

            var dialogs=Array.from(document.querySelectorAll("[role='dialog'],[aria-modal='true']")).filter(function(dialog){
              return !dialog.closest('#web-scanner-dialog-proxy');
            });
            document.querySelectorAll("[data-testid='confirm-popup']").forEach(function(popup){
              if(popup.closest('#web-scanner-dialog-proxy'))return;
              var owner=popup.closest("[role='dialog'],[aria-modal='true']")||popup;
              if(!dialogs.includes(owner))dialogs.push(owner);
            });
            dialogs.forEach(function(dialog){
              if(!dialog.isConnected)return;
              var media=dialog.querySelector("[data-testid='media-editor-canvas'],[data-testid='media-viewer']");
              if(media)return;
              var rect=dialog.getBoundingClientRect();
              var dialogStyle=getComputedStyle(dialog);
              if(dialogStyle.display==='none'||dialogStyle.visibility==='hidden')return;
              var card=dialog.querySelector("[data-testid='confirm-popup'],[data-animate-modal-popup='true'],[role='document']");
              var isLayer=(card&&card!==dialog)||rect.width>=window.innerWidth*.78||rect.height>=window.innerHeight*.78;
              if(isLayer){
                dialog.setAttribute('data-web-scanner-modal-layer','true');
                if(!card){
                  card=Array.from(dialog.children).find(function(child){
                    var box=child.getBoundingClientRect();
                    return box.width>80&&box.height>40&&
                      (box.width<window.innerWidth*.92||box.height<window.innerHeight*.92);
                  })||dialog.firstElementChild;
                }
                if(card)card.setAttribute('data-web-scanner-modal-card','true');
              }else{
                dialog.setAttribute('data-web-scanner-modal-self','true');
                card=dialog;
              }
              var host=dialog.parentElement;
              while(host&&host!==document.body&&host!==document.documentElement){
                host.setAttribute('data-web-scanner-modal-host','true');
                host=host.parentElement;
              }
              var buttons=card?Array.from(card.querySelectorAll("button,[role='button']")).filter(function(button){
                var box=button.getBoundingClientRect();
                return box.width>0&&box.height>0;
              }):[];
              if(buttons.length){
                var actions=buttons.reduce(function(owner,button){return commonAncestor(owner,button);});
                if(actions&&actions!==card&&card.contains(actions)){
                  actions.setAttribute('data-web-scanner-modal-actions','true');
                }
              }
            });

            document.querySelectorAll('[data-web-scanner-floating]').forEach(function(node){
              node.removeAttribute('data-web-scanner-floating');
              node.style.removeProperty('translate');
            });
            document.querySelectorAll("[role='menu'],[role='listbox'],[data-animate-dropdown-menu='true']").forEach(function(surface){
              if(surface.closest('#web-scanner-dialog-proxy'))return;
              var rect=surface.getBoundingClientRect();
              if(rect.width<2||rect.height<2)return;
              surface.setAttribute('data-web-scanner-floating','true');
              var host=surface.parentElement;
              while(host&&host!==document.body&&host!==document.documentElement){
                host.setAttribute('data-web-scanner-modal-host','true');
                host=host.parentElement;
              }
            });
            api.syncDialogProxy();

            requestAnimationFrame(function(){
              var viewport=window.visualViewport;
              var width=viewport?viewport.width:window.innerWidth;
              var height=viewport?viewport.height:window.innerHeight;
              document.querySelectorAll('[data-web-scanner-floating]').forEach(function(surface){
                var rect=surface.getBoundingClientRect(),dx=0,dy=0;
                if(rect.right>width-8)dx=width-8-rect.right;
                if(rect.left+dx<8)dx+=8-(rect.left+dx);
                if(rect.bottom>height-8)dy=height-8-rect.bottom;
                if(rect.top+dy<8)dy+=8-(rect.top+dy);
                if(dx||dy)surface.style.setProperty('translate',(dx/$scale)+'px '+(dy/$scale)+'px','important');
              });
            });
          };

          api.apply=function(){
            document.body.classList.toggle('web-scanner-list',api.mode==='list');
            document.body.classList.toggle('web-scanner-detail',api.mode==='detail');
            api.addBackButton();
            api.markMobileSurfaces();
            if(window.Android&&window.Android.postMessage){
              window.Android.postMessage(api.mode==='detail'?'entryMessageDetail':'leaveMessageDetail');
            }
          };
          api.showList=function(){api.mode='list';api.mark();api.apply();};
          api.showDetail=function(){
            api.mark();
            if(!document.querySelector('#main'))return false;
            api.mode='detail';api.apply();return true;
          };
          api.refresh=function(){
            api.updateViewport();
            var pane=document.querySelector("#pane-side,[data-testid='chat-list']");
            var main=document.querySelector('#main');
            // WhatsApp temporarily removes #main while its media editor is
            // mounted. Keep the established detail layout during that state;
            // remapping the root here classifies the editor as an auxiliary
            // pane, hides it, and drops the selected attachment.
            if(api.mode==='detail'&&!main&&api.root&&api.root.isConnected&&
               api.list&&api.list.isConnected){
              api.apply();
              return;
            }
            var structureChanged=pane!==api.paneNode||main!==api.mainNode||
              !api.root||!api.root.isConnected||!api.list||!api.list.isConnected;
            if(structureChanged)api.mark();
            if(api.mode==='detail'&&!(api.detail&&api.detail.isConnected)&&
               !document.querySelector('#main'))api.mode='list';
            api.apply();
          };
          window.__webScannerMobileLayout=api;

          api.updateViewport();
          var viewportListener=function(){api.updateViewport();api.markMobileSurfaces();};
          window.addEventListener('resize',viewportListener);
          if(window.visualViewport)window.visualViewport.addEventListener('resize',viewportListener);
          window.__webScannerViewportCleanup=function(){
            window.removeEventListener('resize',viewportListener);
            if(window.visualViewport)window.visualViewport.removeEventListener('resize',viewportListener);
          };

          if(window.__webScannerClickHandler){
            document.removeEventListener('click',window.__webScannerClickHandler,true);
          }
          window.__webScannerClickHandler=function(event){
            var pane=document.querySelector("#pane-side,[data-testid='chat-list']");
            if(!pane||!pane.contains(event.target))return;
            var row=event.target.closest("[role='listitem'],[role='row'],[data-testid='cell-frame-container']");
            if(!row)return;
            setTimeout(function(){api.showDetail();},120);
            setTimeout(function(){api.showDetail();},450);
          };
          document.addEventListener('click',window.__webScannerClickHandler,true);

          if(!window.__webScannerMobileObserver){
            window.__webScannerMobileObserver=new MutationObserver(function(){
              requestAnimationFrame(function(){api.updateViewport();api.markMobileSurfaces();});
              clearTimeout(window.__webScannerMobileTimer);
              window.__webScannerMobileTimer=setTimeout(function(){api.refresh();},160);
              clearTimeout(window.__webScannerModalTimer);
              window.__webScannerModalTimer=setTimeout(function(){
                api.updateViewport();api.markMobileSurfaces();
              },420);
            });
            window.__webScannerMobileObserver.observe(document.body,{childList:true,subtree:true});
          }
          api.showList();
          return 'installed';
        })()
    """.trimIndent()

    const val MODE_QR = "toQR"
    const val MODE_CODE = "toCode"

    const val BACK_SCRIPT = """
        (function(){
          try {
            document.dispatchEvent(new KeyboardEvent('keydown', {
              key: 'Escape', code: 'Escape', keyCode: 27, which: 27, bubbles: true, cancelable: true
            }));
          } catch (e) {}
          var api=window.__webScannerMobileLayout;
          if(api&&api.mode==='detail'){
            api.showList();
            if(window.Android&&window.Android.postMessage){
              window.Android.postMessage('leaveMessageDetail');
            }
            return true;
          }
          return false;
        })()
    """

    /**
     * Clicks WhatsApp Web's own "Link with phone number" / "Link with QR code" link button
     * on the live page, matching `WebActivity.changeLoginMode()` in the original app.
     */
    const val TOGGLE_LOGIN_MODE_SCRIPT = """
        (function(){
          var arrows = document.querySelectorAll('span[data-icon="wa-brand-arrow-right"]');
          if (arrows && arrows.length > 0) {
            var btn = arrows[0].closest('button,[role="button"],a,div[tabindex]') || arrows[0];
            btn.click();
            return 'clicked-arrow';
          }
          var chevrons = document.querySelectorAll('span[data-icon="chevron"]');
          if (chevrons && chevrons.length > 0) {
            var last = chevrons[chevrons.length - 1];
            var cBtn = last.closest('button,[role="button"],a,div[tabindex]') || last;
            cBtn.click();
            return 'clicked-chevron';
          }
          var items = Array.from(document.querySelectorAll('button,a,[role="button"],span[role="button"]'));
          var target = items.find(function(e){
            var t = (e.innerText || e.textContent || '').toLowerCase();
            return t.includes('phone number') || t.includes('số điện thoại') ||
                   t.includes('qr code') || t.includes('mã qr');
          });
          if (target) {
            target.click();
            return 'clicked-text';
          }
          return 'not-found';
        })()
    """

    /**
     * Installs the pre-login & post-login DOM observer matching `y.java` + `WebActivity.java`
     * in the original app:
     * - Scales the login card cleanly to mobile screen width (`window.innerWidth / 580`)
     * - Detects QR mode (`toQR`) vs Phone Number / Code mode (`toCode`)
     * - Formats the 8-character phone link code (`flexWrap = 'wrap'`) and auto-copies `data-link-code`
     * - Detects login completion (`logSuccess`)
     * - Intercepts input taps when Keyboard Lock is enabled (`openKeyBroad`)
     */
    fun installDualAppObserver(webMode: Int, keyboardLocked: Boolean): String = """
        (function(){
          window.__webScannerKeyboardLocked = $keyboardLocked;
          window.__webScannerWebMode = $webMode;

          if (!window.__webScannerOriginalFocus) {
            window.__webScannerOriginalFocus = HTMLInputElement.prototype.focus;
          }
          HTMLInputElement.prototype.focus = function() {
            if (window.__webScannerKeyboardLocked) return;
            return window.__webScannerOriginalFocus.apply(this, arguments);
          };

          if (!window.__webScannerKbClickInstalled) {
            window.__webScannerKbClickInstalled = true;
            function checkInputNode(node) {
              if (!node || !node.classList) return false;
              var tag = (node.tagName || '').toUpperCase();
              if (tag === 'DIV' && (
                  node.classList.contains('html-input') ||
                  node.classList.contains('selectable-text') ||
                  node.classList.contains('copyable-text') ||
                  node.getAttribute('contenteditable') === 'true'
              )) return true;
              if (tag === 'P' && node.classList.contains('copyable-text')) return true;
              if (tag === 'INPUT' || tag === 'TEXTAREA') return true;
              return false;
            }
            document.addEventListener('click', function(ev) {
              if (!window.__webScannerKeyboardLocked) return;
              var t = ev.target;
              if (!t) return;
              if (checkInputNode(t) || (t.closest && t.closest('[contenteditable="true"],input,textarea,.copyable-text,.selectable-text'))) {
                if (window.Android && window.Android.postMessage) {
                  window.Android.postMessage('openKeyBroad');
                }
              }
            }, true);
          }

          function syncState() {
            var hasMainHeader = Boolean(
              document.querySelector("#pane-side,[data-testid='chat-list'],header,[data-testid='chatlist-header']")
            );
            if (hasMainHeader) {
              if (!window.__webScannerLoggedSuccessSent) {
                window.__webScannerLoggedSuccessSent = true;
                if (window.Android && window.Android.postMessage) {
                  window.Android.postMessage('logSuccess');
                }
              }
              if (window.__webScannerWebMode === 1) {
                var styleEl = document.getElementById('web-scanner-mobile-layout');
                if (styleEl) styleEl.remove();
                document.documentElement.style.zoom = '1';
                document.documentElement.style.width = '100%';
                document.body.style.zoom = '1';
                document.body.classList.remove('web-scanner-list', 'web-scanner-detail');
              }
              return 'chat';
            }

            window.__webScannerLoggedSuccessSent = false;

            // Pre-login: scale the 580px WhatsApp Web login card to fit the mobile screen cleanly
            var loginZoom = Math.min(1, Math.max(0.52, window.innerWidth / 580));
            document.documentElement.style.zoom = '1';
            document.documentElement.style.width = '100%';
            document.body.style.zoom = String(loginZoom);
            var appNode = document.getElementById('app');
            if (appNode && appNode.firstElementChild) {
              appNode.firstElementChild.style.overflowX = 'hidden';
            }

            var qrNode = document.querySelector('div[data-ref^="https://wa.me/settings/linked_devices"],[data-testid="qrcode"],canvas');
            if (qrNode) {
              if (!window.__webScannerOpenedQrHelper) {
                window.__webScannerOpenedQrHelper = true;
                if (window.Android && window.Android.postMessage) {
                  window.Android.postMessage('openHelper');
                }
              }
              if (window.__webScannerLoginMode !== 'QR') {
                window.__webScannerLoginMode = 'QR';
                if (window.Android && window.Android.postMessage) {
                  window.Android.postMessage('toQR');
                }
              }
            }

            var codeScreen = document.querySelector('div[aria-details="link-device-phone-number-code-screen-instructions"]');
            if (codeScreen && codeScreen.children && codeScreen.children.length > 0) {
              var codeRow = codeScreen.children[0];
              codeRow.style.display = 'flex';
              codeRow.style.flexWrap = 'wrap';
              codeRow.style.justifyContent = 'center';
              codeRow.style.gap = '6px';
              if (!window.__webScannerOpenedCodeHelper) {
                window.__webScannerOpenedCodeHelper = true;
                if (window.Android && window.Android.postMessage) {
                  window.Android.postMessage('openCodeHelper');
                }
              }
              var linkCode = codeScreen.getAttribute('data-link-code');
              if (linkCode && window.__webScannerLastCopiedCode !== linkCode) {
                window.__webScannerLastCopiedCode = linkCode;
                if (window.Android && window.Android.copyCode) {
                  window.Android.copyCode(linkCode);
                }
              }
            }

            var phoneForm = document.querySelector('form,input[type="tel"],div[aria-details="link-device-phone-number-code-screen-instructions"]');
            if (phoneForm && !qrNode) {
              if (window.__webScannerLoginMode !== 'CODE') {
                window.__webScannerLoginMode = 'CODE';
                if (window.Android && window.Android.postMessage) {
                  window.Android.postMessage('toCode');
                }
              }
            }
            return qrNode || phoneForm ? 'login' : 'loading';
          }

          if (!window.__webScannerDualObserver) {
            window.__webScannerDualObserver = new MutationObserver(function() {
              clearTimeout(window.__webScannerDualTimer);
              window.__webScannerDualTimer = setTimeout(syncState, 120);
            });
            if (document.body) {
              window.__webScannerDualObserver.observe(document.body, { childList: true, subtree: true });
            }
          }
          return syncState();
        })()
    """.trimIndent()
}
