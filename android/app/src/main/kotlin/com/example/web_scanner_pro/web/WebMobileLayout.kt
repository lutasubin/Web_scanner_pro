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
            [data-web-scanner-root]{width:100%!important;max-width:none!important;overflow:hidden!important;}
            [data-web-scanner-pane]{width:100%!important;min-width:100%!important;max-width:100%!important;flex:1 1 100%!important;}
            body.web-scanner-list [data-web-scanner-pane='detail'],
            body.web-scanner-list [data-web-scanner-pane='aux'],
            body.web-scanner-detail [data-web-scanner-pane='list'],
            body.web-scanner-detail [data-web-scanner-pane='aux']{display:none!important;}
            body.web-scanner-list [data-web-scanner-pane='list'],
            body.web-scanner-detail [data-web-scanner-pane='detail']{display:flex!important;visibility:visible!important;transform:none!important;}
            body.web-scanner-list #pane-side,
            body.web-scanner-detail #main{width:100%!important;min-width:100%!important;max-width:100%!important;}
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

          var api={mode:'list',root:null,list:null,detail:null};

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

            document.querySelectorAll('[data-web-scanner-pane]').forEach(function(node){
              node.removeAttribute('data-web-scanner-pane');
            });
            document.querySelectorAll('[data-web-scanner-root]').forEach(function(node){
              node.removeAttribute('data-web-scanner-root');
            });
            root.setAttribute('data-web-scanner-root','true');
            listBranch.setAttribute('data-web-scanner-pane','list');
            if(detailBranch)detailBranch.setAttribute('data-web-scanner-pane','detail');
            Array.from(root.children).forEach(function(child){
              if(child===listBranch||child===detailBranch)return;
              var box=child.getBoundingClientRect();
              if(box.height>window.innerHeight*0.55)child.setAttribute('data-web-scanner-pane','aux');
            });
            api.root=root;api.list=listBranch;api.detail=detailBranch;
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

          api.apply=function(){
            document.body.classList.toggle('web-scanner-list',api.mode==='list');
            document.body.classList.toggle('web-scanner-detail',api.mode==='detail');
            api.addBackButton();
            window.scrollTo(0,0);
          };
          api.showList=function(){api.mode='list';api.mark();api.apply();};
          api.showDetail=function(){
            api.mark();
            if(!document.querySelector('#main'))return false;
            api.mode='detail';api.apply();return true;
          };
          api.refresh=function(){
            api.mark();
            if(api.mode==='detail'&&!document.querySelector('#main'))api.mode='list';
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
              window.__webScannerMobileTimer=setTimeout(function(){api.refresh();},80);
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
