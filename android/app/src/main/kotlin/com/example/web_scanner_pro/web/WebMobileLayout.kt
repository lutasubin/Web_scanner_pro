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
            [data-web-scanner-pane='nav']{display:flex!important;visibility:visible!important;width:56px!important;min-width:56px!important;max-width:56px!important;flex:0 0 56px!important;transform:none!important;}
            [data-web-scanner-pane='list']{width:calc(100% - 56px)!important;min-width:calc(100% - 56px)!important;max-width:calc(100% - 56px)!important;flex:0 0 calc(100% - 56px)!important;overflow:hidden!important;}
            [data-web-scanner-pane='detail']{width:100%!important;min-width:100%!important;max-width:100%!important;flex:0 0 100%!important;overflow:hidden!important;}
            body.web-scanner-list [data-web-scanner-pane='detail'],
            body.web-scanner-list [data-web-scanner-pane='aux'],
            body.web-scanner-detail [data-web-scanner-pane='nav'],
            body.web-scanner-detail [data-web-scanner-pane='list']{display:none!important;}
            body.web-scanner-list [data-web-scanner-pane='nav'],
            body.web-scanner-list [data-web-scanner-pane='list'],
            body.web-scanner-detail [data-web-scanner-pane='detail']{display:flex!important;visibility:visible!important;transform:none!important;}
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
            body.web-scanner-detail [role='dialog']{position:fixed!important;inset:0!important;width:calc(100vw / $scale)!important;min-width:0!important;max-width:none!important;height:calc(100vh / $scale)!important;display:flex!important;align-items:center!important;justify-content:center!important;padding:16px!important;overflow:hidden!important;}
            body.web-scanner-detail [role='dialog'] [data-testid='confirm-popup']{width:100%!important;min-width:0!important;max-width:328px!important;margin:auto!important;border-radius:14px!important;}
            body.web-scanner-detail [role='dialog'] [data-testid='confirm-popup']>div{width:100%!important;min-width:0!important;}
            body.web-scanner-detail [role='menu']{max-width:calc(100vw / $scale - 24px)!important;max-height:calc(100vh / $scale - 24px)!important;overflow:auto!important;}
            #web-scanner-chat-back{display:flex!important;align-items:center!important;justify-content:center!important;width:44px!important;min-width:44px!important;height:44px!important;margin:0 2px 0 0!important;padding:0!important;border:0!important;background:transparent!important;color:#111!important;font:400 34px/1 sans-serif!important;cursor:pointer!important;}
          `;
          document.documentElement.style.zoom='$scale';
          document.documentElement.style.width='${expandedWidth}%';
          document.documentElement.style.overflowX='hidden';
          document.body.style.overflowX='hidden';

          if(window.__webScannerMobileLayout){
            window.__webScannerMobileLayout.refresh();
            return 'updated';
          }

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

          var api={mode:'list',root:null,nav:null,list:null,detail:null,paneNode:null,mainNode:null};

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
            if(!pane)return false;
            var main=document.querySelector('#main');
            var root=null,listBranch=null,detailBranch=null;
            if(main){
              root=commonAncestor(pane,main);
              if(root&&root!==document.body&&root!==document.documentElement){
                listBranch=directChild(root,pane);
                detailBranch=directChild(root,main);
                if(listBranch===detailBranch){root=null;listBranch=null;detailBranch=null;}
              }
            }
            if(!root){
              var found=api.findListRoot(pane);
              if(found){root=found.root;listBranch=found.list;}
            }
            if(!root||!listBranch)return false;

            var navBranch=Array.from(root.children).find(function(child){
              var labels=Array.from(child.querySelectorAll('[aria-label]')).map(function(node){
                return (node.getAttribute('aria-label')||'').toLowerCase();
              });
              var hasChats=labels.some(function(label){return label==='chats'||label.includes('đoạn chat');});
              var hasCalls=labels.some(function(label){return label==='calls'||label.includes('cuộc gọi');});
              var hasStatus=labels.some(function(label){return label==='status'||label.includes('trạng thái');});
              return hasChats&&(hasCalls||hasStatus);
            });
            if(api.root===root&&api.nav===navBranch&&api.list===listBranch&&
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
            root.setAttribute('data-web-scanner-root','true');
            if(navBranch)navBranch.setAttribute('data-web-scanner-pane','nav');
            listBranch.setAttribute('data-web-scanner-pane','list');
            if(detailBranch)detailBranch.setAttribute('data-web-scanner-pane','detail');
            Array.from(root.children).forEach(function(child){
              if(child===navBranch||child===listBranch||child===detailBranch)return;
              var box=child.getBoundingClientRect();
              if(box.height>window.innerHeight*0.55)child.setAttribute('data-web-scanner-pane','aux');
            });
            api.root=root;api.nav=navBranch;api.list=listBranch;api.detail=detailBranch;
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

          };

          api.apply=function(){
            document.body.classList.toggle('web-scanner-list',api.mode==='list');
            document.body.classList.toggle('web-scanner-detail',api.mode==='detail');
            api.addBackButton();
            api.markMobileSurfaces();
          };
          api.showList=function(){api.mode='list';api.mark();api.apply();};
          api.showDetail=function(){
            api.mark();
            if(!document.querySelector('#main'))return false;
            api.mode='detail';api.apply();return true;
          };
          api.refresh=function(){
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

          document.addEventListener('click',function(event){
            var pane=document.querySelector("#pane-side,[data-testid='chat-list']");
            if(!pane||!pane.contains(event.target))return;
            var row=event.target.closest("[role='listitem'],[role='row'],[data-testid='cell-frame-container']");
            if(!row)return;
            setTimeout(function(){api.showDetail();},120);
            setTimeout(function(){api.showDetail();},450);
          },true);

          if(!window.__webScannerMobileObserver){
            window.__webScannerMobileObserver=new MutationObserver(function(){
              clearTimeout(window.__webScannerMobileTimer);
              window.__webScannerMobileTimer=setTimeout(function(){api.refresh();},160);
            });
            window.__webScannerMobileObserver.observe(document.body,{childList:true,subtree:true});
          }
          api.showList();
          return 'installed';
        })()
    """.trimIndent()

    const val BACK_SCRIPT = """
        (function(){
          var api=window.__webScannerMobileLayout;
          if(api&&api.mode==='detail'){api.showList();return true;}
          return false;
        })()
    """
}
