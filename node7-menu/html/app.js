const app=document.getElementById('app');
const itemsNode=document.getElementById('items');
const titleNode=document.getElementById('title');
const subtitleNode=document.getElementById('subtitle');
const descriptionNode=document.getElementById('description');
const counterNode=document.getElementById('counter');
const resource=typeof GetParentResourceName==='function'?GetParentResourceName():'node7-menu';

let menu=null;
let activeIndex=0;
let selectable=[];

function post(name,data={}) {
 return fetch(`https://${resource}/${name}`,{
  method:'POST',
  headers:{'Content-Type':'application/json'},
  body:JSON.stringify(data)
 }).then(r=>r.json());
}

function render(){
 if(!menu)return;
 itemsNode.innerHTML='';
 selectable=[];

 (menu.items||[]).forEach((item,index)=>{
  if(item.hidden)return;

  const button=document.createElement('button');
  button.type='button';
  button.className='menu-item';
  if(item.disabled)button.classList.add('disabled');

  const suffix=item.submenu
   ? '<span class="menu-arrow">›</span>'
   : item.ace
    ? '<span class="menu-lock">ACE</span>'
    : '<span></span>';

  button.innerHTML=`
   <span class="menu-number">${String(index+1).padStart(2,'0')}</span>
   <span class="menu-copy">
    <strong>${escapeHtml(item.label)}</strong>
    <span>${escapeHtml(item.description||'')}</span>
   </span>
   ${suffix}
  `;

  if(!item.disabled){
   selectable.push({button,index});
   button.onclick=()=>select(index);
  }

  itemsNode.appendChild(button);
 });

 activeIndex=Math.min(activeIndex,Math.max(selectable.length-1,0));
 updateActive();
}

function escapeHtml(value){
 return String(value??'').replace(/[&<>"']/g,c=>({
  '&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#039;'
 }[c]));
}

function updateActive(){
 selectable.forEach((entry,index)=>{
  entry.button.classList.toggle('active',index===activeIndex);
 });
 const total=selectable.length;
 counterNode.textContent=total?`${activeIndex+1} / ${total}`:'0 / 0';
 selectable[activeIndex]?.button.scrollIntoView({block:'nearest'});
}

async function select(rawIndex){
 const result=await post('select',{index:rawIndex+1}).catch(()=>({ok:false}));
 if(result.denied){
  const entry=selectable.find(e=>e.index===rawIndex);
  if(entry){
   entry.button.classList.add('denied');
   setTimeout(()=>entry.button.classList.remove('denied'),600);
  }
 }
}

window.addEventListener('message',event=>{
 const data=event.data||{};

 if(data.action==='open'){
  menu=data.menu||{};
  activeIndex=0;
  titleNode.textContent=menu.title||'NODE7 LABS';
  subtitleNode.textContent=menu.subtitle||'FRONTIER MENU';
  descriptionNode.textContent=menu.description||'';
  if(data.theme?.accent){
   document.documentElement.style.setProperty('--gold',data.theme.accent);
  }
  app.classList.remove('hidden');
  render();
 }

 if(data.action==='close'){
  app.classList.add('hidden');
  menu=null;
 }
});

window.addEventListener('keydown',event=>{
 if(app.classList.contains('hidden'))return;

 if(event.key==='ArrowDown'){
  event.preventDefault();
  if(selectable.length){
   activeIndex=(activeIndex+1)%selectable.length;
   updateActive();
  }
 }

 if(event.key==='ArrowUp'){
  event.preventDefault();
  if(selectable.length){
   activeIndex=(activeIndex-1+selectable.length)%selectable.length;
   updateActive();
  }
 }

 if(event.key==='Enter'){
  event.preventDefault();
  const entry=selectable[activeIndex];
  if(entry)select(entry.index);
 }

 if(event.key==='Backspace'){
  event.preventDefault();
  post('back').catch(()=>{});
 }

 if(event.key==='Escape'){
  event.preventDefault();
  post('close').catch(()=>{});
 }
});
