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
            [data-web-scanner-content]{display:flex!important;position:relative!important;left:0!important;right:auto!important;width:calc(100% - 56px)!important;min-width:calc(100% - 56px)!important;max-width:calc(100% - 56px)!important;flex:0 0 calc(100% - 56px)!important;height:100%!important;overflow:hidden!important;pointer-events:auto!important;z-index:5!important;}
            [data-web-scanner-pane='nav']{display:flex!important;visibility:visible!important;width:56px!important;min-width:56px!important;max-width:56px!important;flex:0 0 56px!important;transform:none!important;}
            [data-web-scanner-pane='list']{width:calc(100% - 56px)!important;min-width:calc(100% - 56px)!important;max-width:calc(100% - 56px)!important;flex:0 0 calc(100% - 56px)!important;overflow:hidden!important;}
            [data-web-scanner-content] [data-web-scanner-pane='list'],
            body.web-scanner-list [data-web-scanner-content] [data-testid='drawer-left']{display:flex!important;width:100%!important;min-width:100%!important;max-width:100%!important;flex:0 0 100%!important;height:100%!important;margin-left:0!important;border-left-width:0!important;pointer-events:auto!important;}
            body.web-scanner-list [data-web-scanner-content] [data-testid='drawer-middle']:not(:has(header)){display:none!important;}
            body.web-scanner-list [data-web-scanner-content] [data-testid='drawer-middle']:has(> div > span:not(:empty)):not(:has([data-testid='intro-panel'])):not(:has([data-testid='empty-state-drawer'])){display:block!important;position:absolute!important;inset:0!important;width:100%!important;min-width:100%!important;max-width:100%!important;height:100%!important;margin-left:0!important;pointer-events:auto!important;z-index:350!important;}
            [data-web-scanner-pane='detail']{width:100%!important;min-width:100%!important;max-width:100%!important;flex:0 0 100%!important;overflow:hidden!important;}
            body.web-scanner-list [data-web-scanner-pane='detail'],
            body.web-scanner-list [data-web-scanner-pane='aux'],
            body.web-scanner-detail [data-web-scanner-pane='nav'],
            body.web-scanner-detail [data-web-scanner-pane='list'],
            body.web-scanner-detail [data-web-scanner-pane='aux'],
            body.web-scanner-detail [data-web-scanner-content]:not(:has([data-web-scanner-pane='detail'])){display:none!important;}
            body.web-scanner-list [data-web-scanner-pane='nav'],
            body.web-scanner-list [data-web-scanner-pane='list'],
            body.web-scanner-detail [data-web-scanner-pane='detail']{display:flex!important;visibility:visible!important;transform:none!important;}
            body.web-scanner-detail [data-web-scanner-content]:has([data-web-scanner-pane='detail']){left:0!important;width:100%!important;min-width:100%!important;max-width:100%!important;flex-basis:100%!important;}
            [data-testid='media-hub-modal'],div:has(> [data-testid='media-hub-modal']){min-width:0!important;max-width:100%!important;width:100%!important;flex-wrap:wrap!important;}
            [data-testid='popup-contents'] > div:first-child:not(:only-child){flex-wrap:wrap!important;height:auto!important;min-height:0!important;}
            [data-testid='media-viewer-modal'] > div:first-child{overflow-x:auto!important;overflow-y:hidden!important;-webkit-overflow-scrolling:touch!important;}
            [style*='--x5t84p7']{left:16px!important;right:16px!important;width:calc(100% - 32px)!important;margin:0!important;}
            [style*='--x5t84p7'] [role='grid'] > :last-child > :last-child > :last-child > :last-child{overflow-x:auto!important;}
            [style*='--x5t84p7'] [role='grid'] > :last-child > :last-child > :last-child > :last-child > :first-child > :first-child{overflow:visible!important;}
            #wa-popovers-bucket > div{top:80px!important;left:50%!important;transform:translate(-50%,0)!important;}
            [role='dialog']{min-width:0!important;max-width:100%!important;box-sizing:border-box!important;}
            [role='dialog'] > div:first-child{width:100%!important;max-width:100%!important;min-width:0!important;box-sizing:border-box!important;}
            div[role='dialog'] [role='dialog'],[role='dialog'] [data-animate-modal-popup='true']:not([data-testid='media-hub-modal']),[role='dialog'] [data-testid='confirm-popup']{width:calc(100% - 24px)!important;max-width:360px!important;min-width:0!important;margin:auto!important;box-sizing:border-box!important;}
            .three .xssin3l.xssin3l{width:100%;max-width:unset;z-index:360;}
            .x121pien{width:260px;}
            .xs8rnei,.xvue9z,.x16m5f1z,.x1peuizl,._asag{width:100%;}
            .xpb48g7,.x17q2evi{min-width:unset;}
            .x1esq4s8{width:unset;}
            .x13a6bvl{justify-content:center;}
            .x6ttaax,.x19hm5wc{width:var(--width-album-grid-bubble)!important;height:var(--width-album-grid-bubble)!important;}
            ._ao_l{left:0px!important;width:100%;}
            ._asag{margin-left:0;left:0!important;}
            .x1y332i5{overflow-x:auto!important;}
            .xnnlda6{height:56px;overflow-x:auto;}
            .xmzvs34{padding-left:4px;}
            .xf159sx{padding-right:4px;}
            .xtssl2i{padding-left:10px;}
            .xp48ta0{padding-right:10px;}
            .x1dr59a3{height:100%;}
            .xwzfr38{min-height:120px;}
            .xdi6fk3{box-sizing:border-box;}
            #web-scanner-status-save-btn{position:fixed!important;right:16px!important;bottom:24px!important;z-index:2147483645!important;display:flex!important;align-items:center!important;gap:6px!important;padding:10px 16px!important;border-radius:999px!important;border:none!important;background:#08C567!important;color:#ffffff!important;font:600 14px/1.2 sans-serif!important;box-shadow:0 6px 20px rgba(0,0,0,.38)!important;cursor:pointer!important;}
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
            [data-web-scanner-floating]{z-index:2147483002!important;max-width:calc(var(--web-scanner-vw) - 16px)!important;max-height:calc(var(--web-scanner-vh) - 16px)!important;overflow:auto!important;overscroll-behavior:contain!important;box-sizing:border-box!important;}
            #web-scanner-chat-back{display:flex!important;align-items:center!important;justify-content:center!important;width:44px!important;min-width:44px!important;height:44px!important;margin:0 2px 0 0!important;padding:0!important;border:0!important;background:transparent!important;color:#111!important;font:400 34px/1 sans-serif!important;cursor:pointer!important;}
          `;
          document.documentElement.style.zoom='$scale';
          document.documentElement.style.width='${expandedWidth}%';
          document.documentElement.style.overflowX='hidden';
          document.documentElement.style.setProperty('--x1oim50r','10px');
          document.documentElement.style.setProperty('--x53dyk0','10px');
          document.documentElement.style.setProperty('--width-msg-bubble-with-media','260px');
          document.documentElement.style.setProperty('--width-album-grid-bubble','125px');
          document.body.style.overflowX='hidden';

          var VERSION=16;
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

          var api={version:VERSION,mode:'list',root:null,content:null,nav:null,list:null,detail:null,paneNode:null,mainNode:null,drawerSig:''};

          api.updateViewport=function(){
            var viewport=window.visualViewport;
            var width=(viewport?viewport.width:window.innerWidth)/$scale;
            var height=(viewport?viewport.height:window.innerHeight)/$scale;
            document.documentElement.style.setProperty('--web-scanner-vw',Math.max(80,width)+'px');
            document.documentElement.style.setProperty('--web-scanner-vh',Math.max(80,height)+'px');
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
            var screen=document.querySelector("[data-testid='wa-web-main-screen']");
            var root=(screen&&screen.firstElementChild)||document.querySelector('#app .two');
            var pane=document.querySelector("#pane-side,[data-testid='chat-list']");
            var main=document.querySelector('#main');
            if(!root&&pane){
              var found=api.findListRoot(pane);
              if(found)root=found.root;
            }
            if(!root)return false;

            var navigationHeader=root.querySelector("[data-testid='chatlist-header']")||
              document.querySelector("[data-testid='chatlist-header']");
            var navBranch=(navigationHeader&&root.contains(navigationHeader))
              ?directChild(root,navigationHeader)
              :Array.from(root.children).find(function(child){
                var labels=Array.from(child.querySelectorAll('[aria-label]')).map(function(node){
                  return (node.getAttribute('aria-label')||'').toLowerCase();
                });
                var hasChats=labels.some(function(label){return label==='chats'||label.includes('đoạn chat');});
                var hasCalls=labels.some(function(label){return label==='calls'||label.includes('cuộc gọi');});
                var hasStatus=labels.some(function(label){return label==='status'||label.includes('trạng thái');});
                return hasChats&&(hasCalls||hasStatus);
              });

            var drawerLeft=root.querySelector("[data-testid='drawer-left']");
            var drawerMiddle=root.querySelector("[data-testid='drawer-middle']");
            var drawerLeftHasContent=Boolean(drawerLeft&&(
              (drawerLeft.textContent||'').trim().length>0||
              drawerLeft.querySelector("[data-testid],header,button,[role='button'],[role='listitem']")
            ));
            var drawerMiddleHasActive=Boolean(drawerMiddle&&
              drawerMiddle.querySelector(':scope > div > span:not(:empty)')&&
              !drawerMiddle.querySelector("[data-testid='intro-panel']")&&
              !drawerMiddle.querySelector("[data-testid='empty-state-drawer']")
            );
            var drawerSignature=drawerLeftHasContent+':'+drawerMiddleHasActive+':'+
              (drawerLeft?drawerLeft.children.length:0)+':'+
              (drawerLeft&&drawerLeft.querySelector('[data-testid]')?drawerLeft.querySelector('[data-testid]').getAttribute('data-testid'):'');

            var contentBranch=null,listBranch=null,detailBranch=null;
            if(main&&root.contains(main)){
              detailBranch=directChild(root,main);
            }
            if(drawerLeft&&(drawerLeftHasContent||drawerMiddleHasActive)){
              contentBranch=directChild(root,drawerLeft);
              listBranch=drawerLeft;
              if(!detailBranch&&drawerMiddle)detailBranch=drawerMiddle;
            }else if(pane&&root.contains(pane)){
              listBranch=directChild(root,pane);
            }
            if(!listBranch)return false;

            if(api.root===root&&api.content===contentBranch&&api.nav===navBranch&&api.list===listBranch&&
               api.detail===detailBranch&&api.drawerSig===drawerSignature&&root.isConnected&&listBranch.isConnected){
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
              if(child.getAttribute('data-testid')==='drawer-fullscreen'){
                var hasFsContent=Boolean(child.querySelector(':scope > span:not(:empty),[data-testid],header,button,img,video,canvas'));
                if(hasFsContent)return;
              }
              var box=child.getBoundingClientRect();
              if(box.height>window.innerHeight*0.55||child.querySelector("#pane-side,[data-testid='drawer-left'],[data-testid='drawer-middle']")){
                child.setAttribute('data-web-scanner-pane','aux');
              }
            });
            api.root=root;api.content=contentBranch;api.nav=navBranch;
            api.list=listBranch;api.detail=detailBranch;
            api.paneNode=pane;api.mainNode=main;api.drawerSig=drawerSignature;
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

          api.transferStatusMedia=function(src,cacheOnly){
            var bridge=window.WebScannerDownloads;
            if(!bridge||!bridge.saveDataUrl)return;
            fetch(src).then(function(r){return r.blob();}).then(function(blob){
              var reader=new FileReader();
              reader.onload=function(){
                var dataUrl=String(reader.result||'');
                if(dataUrl.startsWith('data:')){
                  bridge.saveDataUrl(dataUrl,src,Boolean(cacheOnly));
                }
              };
              reader.readAsDataURL(blob);
            }).catch(function(){});
          };

          api.syncStatusPlayer=function(){
            var player=document.querySelector("[data-testid='status-player-uie']");
            var existingBtn=document.getElementById('web-scanner-status-save-btn');
            if(!player){
              if(existingBtn)existingBtn.remove();
              return;
            }
            var img=player.querySelector("[data-testid='status-image'] img")||
              Array.from(player.querySelectorAll('img')).find(function(node){
                var src=node.src||'';
                return src.startsWith('blob:')||src.startsWith('https://');
              });
            var video=player.querySelector('video');
            var mediaSrc=(video&&video.src)||(img&&img.src)||'';
            if(mediaSrc.startsWith('blob:')||mediaSrc.startsWith('https:')){
              if(!window.__webScannerCapturedStatuses)window.__webScannerCapturedStatuses={};
              if(!window.__webScannerCapturedStatuses[mediaSrc]){
                window.__webScannerCapturedStatuses[mediaSrc]=true;
                api.transferStatusMedia(mediaSrc,true);
              }
              if(!existingBtn){
                existingBtn=document.createElement('button');
                existingBtn.id='web-scanner-status-save-btn';
                existingBtn.type='button';
                existingBtn.textContent='⬇ Lưu trạng thái';
                existingBtn.addEventListener('click',function(ev){
                  ev.preventDefault();ev.stopPropagation();
                  var currentSrc=existingBtn.getAttribute('data-status-src')||'';
                  if(currentSrc)api.transferStatusMedia(currentSrc,false);
                });
                document.body.appendChild(existingBtn);
              }
              existingBtn.setAttribute('data-status-src',mediaSrc);
            }else if(existingBtn){
              existingBtn.remove();
            }
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

            document.querySelectorAll("div[role='dialog']").forEach(function(dialog){
              if(!dialog.isConnected)return;
              dialog.style.minWidth='unset';
              if(dialog.children&&dialog.children[0]&&!dialog.children[0].hasAttribute('role')){
                dialog.children[0].style.width='-webkit-fill-available';
              }
            });

            document.querySelectorAll('[data-web-scanner-floating]').forEach(function(node){
              node.removeAttribute('data-web-scanner-floating');
              node.style.removeProperty('translate');
            });
            document.querySelectorAll("[role='menu'],[role='listbox'],[data-animate-dropdown-menu='true']").forEach(function(surface){
              if(surface.closest("[data-testid='drawer-left'],[data-testid='drawer-middle']")&&
                 !surface.closest("#wa-popovers-bucket,[data-animate-dropdown-menu='true']"))return;
              var rect=surface.getBoundingClientRect();
              if(rect.width<2||rect.height<2)return;
              surface.setAttribute('data-web-scanner-floating','true');
              var host=surface.parentElement;
              while(host&&host!==document.body&&host!==document.documentElement){
                host.setAttribute('data-web-scanner-modal-host','true');
                host=host.parentElement;
              }
            });
            api.syncStatusPlayer();

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
            api.mark();
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
            var target=event.target;
            if(!target||!target.closest)return;
            var navHeader=target.closest("[data-testid='chatlist-header']");
            if(navHeader){
              var btn=target.closest("button,[role='button']");
              var label=((btn&&(btn.getAttribute('aria-label')||btn.textContent))||'').toLowerCase();
              var navButtons=Array.from(navHeader.querySelectorAll('button'));
              var btnIndex=btn?navButtons.indexOf(btn):-1;
              var isMetaAi=label.includes('meta ai')||btnIndex===5;
              if(isMetaAi){
                setTimeout(function(){api.mark();api.showDetail();},120);
                setTimeout(function(){api.mark();api.showDetail();},380);
              }else{
                api.mode='list';
                setTimeout(function(){api.showList();},60);
                setTimeout(function(){api.showList();},220);
                setTimeout(function(){api.showList();},480);
              }
              return;
            }
            var chatRow=target.closest(
              "#pane-side [role='listitem'],#pane-side [role='row'],#pane-side [data-testid='cell-frame-container']," +
              "[data-testid='newsletter-tab-drawer'] [data-testid='newsletter-tab-newsletter-cell']," +
              "[data-testid='newsletter-tab-drawer'] [data-testid='newsletter-recommended-item']," +
              "[data-testid='newsletter-tab-drawer'] [role='listitem']"
            );
            if(chatRow){
              setTimeout(function(){api.showDetail();},120);
              setTimeout(function(){api.showDetail();},450);
              return;
            }
            var drawerTarget=target.closest("[data-testid='drawer-left'],[data-testid='drawer-middle'],[data-testid='status-player-uie']");
            if(drawerTarget){
              setTimeout(function(){api.refresh();},100);
              setTimeout(function(){api.refresh();},350);
            }
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
          var api=window.__webScannerMobileLayout;
          var statusPlayer=document.querySelector("[data-testid='status-player-uie']");
          if(statusPlayer){
            var rootSpan=statusPlayer;
            while(rootSpan&&rootSpan.parentElement&&rootSpan.parentElement.id!=='app'){
              rootSpan=rootSpan.parentElement;
            }
            var closeStatus=(rootSpan&&rootSpan.querySelector("button[aria-label='Đóng'],button[aria-label='Close'],button[aria-label='Quay lại'],button:has([data-icon*='close']),button:has([data-icon*='back'])"))||null;
            if(closeStatus){closeStatus.click();}
            try{
              document.dispatchEvent(new KeyboardEvent('keydown',{key:'Escape',code:'Escape',keyCode:27,which:27,bubbles:true,cancelable:true}));
            }catch(e){}
            if(api)setTimeout(function(){api.refresh();},120);
            return true;
          }
          var openDialog=document.querySelector("[role='dialog']");
          if(openDialog&&getComputedStyle(openDialog).display!=='none'){
            var closeDlg=openDialog.querySelector("button[aria-label='Đóng'],button[aria-label='Close'],button:has([data-icon*='close'])");
            if(closeDlg){closeDlg.click();}
            try{
              document.dispatchEvent(new KeyboardEvent('keydown',{key:'Escape',code:'Escape',keyCode:27,which:27,bubbles:true,cancelable:true}));
            }catch(e){}
            if(api)setTimeout(function(){api.refresh();},120);
            return true;
          }
          if(api&&api.mode==='detail'){
            var dl=document.querySelector("[data-testid='drawer-left']");
            var dlHasContent=Boolean(dl&&((dl.textContent||'').trim().length>0||dl.querySelector('[data-testid],header,button')));
            if(!dlHasContent){
              try{
                document.dispatchEvent(new KeyboardEvent('keydown',{key:'Escape',code:'Escape',keyCode:27,which:27,bubbles:true,cancelable:true}));
              }catch(e){}
            }
            api.showList();
            if(window.Android&&window.Android.postMessage){
              window.Android.postMessage('leaveMessageDetail');
            }
            return true;
          }
          var dm=document.querySelector("[data-testid='drawer-middle']");
          var dmActive=Boolean(dm&&dm.querySelector(':scope > div > span:not(:empty)')&&!dm.querySelector("[data-testid='intro-panel']")&&!dm.querySelector("[data-testid='empty-state-drawer']"));
          if(dmActive){
            var closeDm=dm.querySelector("button[aria-label='Đóng'],button[aria-label='Close'],button[aria-label='Quay lại'],button:has([data-icon*='close']),button:has([data-icon*='back'])");
            if(closeDm){closeDm.click();}
            try{
              document.dispatchEvent(new KeyboardEvent('keydown',{key:'Escape',code:'Escape',keyCode:27,which:27,bubbles:true,cancelable:true}));
            }catch(e){}
            if(api)setTimeout(function(){api.refresh();},120);
            return true;
          }
          var drawerLeft=document.querySelector("[data-testid='drawer-left']");
          var drawerLeftActive=Boolean(drawerLeft&&((drawerLeft.textContent||'').trim().length>0||drawerLeft.querySelector('[data-testid],header,button')));
          if(drawerLeftActive){
            var subBack=drawerLeft.querySelector("header button:has([data-icon*='back']),header button:has([data-icon*='close']),button[aria-label='Quay lại'],button[aria-label='Đóng']");
            if(subBack&&!drawerLeft.querySelector("[data-testid='status-tab-drawer'],[data-testid='newsletter-tab-drawer'],[data-testid='community-tab-drawer'],[data-testid='calls-tab-drawer'],[data-testid='me-tab-drawer']")){
              subBack.click();
              if(api)setTimeout(function(){api.refresh();},120);
              return true;
            }
            var chatTabBtn=document.querySelector("[data-testid='chatlist-header'] button");
            if(chatTabBtn){
              chatTabBtn.click();
              if(api)setTimeout(function(){api.showList();},100);
              return true;
            }
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
