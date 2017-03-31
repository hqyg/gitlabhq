import JSZip from 'jszip';
import JSZipUtils from 'jszip-utils';
import SketchRender from './sketch_render';

export default class SketchLoader {
  constructor(container) {
    this.container = container;
    this.loadingIcon = this.container.querySelector('.js-loading-icon');

    this.sketchBrowserId = 'sketch-browser';
    this.sketchBrowserPropsId = 'sketch-browser-props';

    this.load();
  }

  load() {
    return this.getZipFile()
      .then(data => {
        return JSZip.loadAsync(data)
      })
      .then(asyncResult => {
        this.sketchRender = new SketchRender(this.sketchBrowserId, this.sketchBrowserPropsId, asyncResult.files);
        return asyncResult.files['previews/preview.png'].async('uint8array')
      })
      .then((content) => {
        const url = window.URL || window.webkitURL;
        const blob = new Blob([new Uint8Array(content)], {
          type: 'image/png',
        });
        const previewUrl = url.createObjectURL(blob);

        this.render(previewUrl);
      })
      .catch(this.error.bind(this));
  }

  getZipFile() {
    return new JSZip.external.Promise((resolve, reject) => {
      JSZipUtils.getBinaryContent(this.container.dataset.endpoint, (err, data) => {
        if (err) {
          reject(err);
        } else {
          resolve(data);
        }
      });
    });
  }

  render(previewUrl) {
    const previewLink = document.createElement('a');
    const previewImage = document.createElement('img');
    const sketchBrowser = document.createElement('aside');
    const sketchBrowserProps = document.createElement('aside');
    const sketchBrowserInner = `
      <div class="sketch-panel">
        <div class="heading">Pages</div>
        <ul>
          <li class="page" v-for="(page, i) in pages" :class="{active: currentPageIndex === i}">
            <a href='#' @click.prevent="pageSelected(i)">{{page.name}}</a>
          </li>
        </ul>
        <div class="heading">{{currentPage.name}}</div>
        <ul>
          <layer v-for="layer in currentPage.layers" @layerselected="layerSelected" :key="layer.do_objectID" :layer="layer"></layer>
        </ul>
      </div>
    `;
    const sketchBrowserPropsInner = `
      <div class="sketch-panel">
        <div class="heading">Properties</div>
        <section class="prop-section">
          <fieldset>
            <legend>Position</legend>
            <label>
              <span>Y</span>
            <input type="text" v-model="currentPos.y" class="form-control" readonly="readonly"/>
            </label>
            <label>
              <span>X</span>
              <input type="text" v-model="currentPos.x" class="form-control" readonly="readonly"/>
            </label>
          </fieldset>
          <fieldset>
            <legend>Size</legend>
            <label>
              <span>W</span>
            <input type="text" v-model="currentPos.width" class="form-control" readonly="readonly"/>
            </label>
            <label>
              <span>H</span>
              <input type="text" v-model="currentPos.height" class="form-control" readonly="readonly"/>
            </label>
          </fieldset>
        </section>
      </div>
    `;

    sketchBrowser.id = this.sketchBrowserId;
    sketchBrowser.className = 'sketch-panel';
    sketchBrowser.innerHTML = sketchBrowserInner;

    sketchBrowserProps.id = this.sketchBrowserPropsId;
    sketchBrowserProps.className = 'sketch-panel';
    sketchBrowserProps.innerHTML = sketchBrowserPropsInner;

    previewLink.href = previewUrl;
    previewLink.target = '_blank';
    previewImage.src = previewUrl;

    previewLink.appendChild(previewImage);
    this.container.appendChild(previewLink);
    this.container.insertBefore(sketchBrowser, previewLink);
    this.container.appendChild(sketchBrowserProps);
    this.sketchRender.render();
    this.removeLoadingIcon();
  }

  error() {
    const errorMsg = document.createElement('p');

    errorMsg.className = 'prepend-top-default append-bottom-default text-center';
    errorMsg.textContent = `
      Cannot show preview. For previews on sketch files, they must have the file format
      introduced by Sketch version 43 and above.
    `;
    this.container.appendChild(errorMsg);

    this.removeLoadingIcon();
  }

  removeLoadingIcon() {
    if (this.loadingIcon) {
      this.loadingIcon.remove();
    }
  }
}
