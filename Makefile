PORTNAME=	photoprism
DISTVERSION=	g260305
CATEGORIES=	www

MAINTAINER=	huoju@devep.net
COMMENT=	Personal Photo Management Web Service
WWW=		https://photoprism.app

LICENSE=	AGPLv3

OPTIONS_DEFINE=		TENSORFLOW
OPTIONS_DEFAULT=	TENSORFLOW
TENSORFLOW_DESC=	Build with TensorFlow support for machine learning features

RUN_DEPENDS=	ffmpeg:multimedia/ffmpeg \
	exiftool:graphics/p5-Image-ExifTool \
	libheif>=1.14.2:graphics/libheif \
	vips>=8.10:graphics/vips

LIB_DEPENDS=	libgio-2.0.so.0:devel/glib20 \
		libgobject-2.0.so.0:devel/glib20 \
		libglib-2.0.so.0:devel/glib20

TENSORFLOW_LIB_DEPENDS=	libtensorflow.so.2:science/py-tensorflow

EXTRACT_DEPENDS=	\
	${RUN_DEPENDS} \
	bash:shells/bash \
	git:devel/git \
	gmake:devel/gmake \
	npm:www/npm-node22 \
	wget:ftp/wget \
	pkg-config:devel/pkgconf

BUILD_DEPENDS=	${EXTRACT_DEPENDS}

USES=		gmake go:1.25,modules python:3.6+,build gettext-runtime
USE_GNOME+=glib20

USE_GITHUB=	yes
GH_ACCOUNT=	lapo-luchini
GH_PROJECT=	photoprism
GH_TAGNAME=	260305-3b8cb2f7c

USE_RC_SUBR=	photoprism
PHOTOPRISM_DATA_DIR=	/var/db/photoprism
SUB_LIST+=	PHOTOPRISM_DATA_DIR=${PHOTOPRISM_DATA_DIR}
SUB_FILES+=	pkg-install pkg-message

BUILD_OS!=uname -s
BUILD_DATE!=date -u +%y%m%d
BUILD_ARCH!=uname -m

.include <bsd.port.options.mk>

.if ! ${PORT_OPTIONS:MTENSORFLOW}
_GO_TAGS=	-tags notf
.endif

post-extract:
	@${REINPLACE_CMD} -e 's|sha1sum|shasum|g' ${WRKSRC}/scripts/download-facenet.sh
	@${REINPLACE_CMD} -e 's|sha1sum|shasum|g' ${WRKSRC}/scripts/download-nasnet.sh
	@${REINPLACE_CMD} -e 's|sha1sum|shasum|g' ${WRKSRC}/scripts/download-nsfw.sh
	@${REINPLACE_CMD} -e 's|--node-env=production||g' ${WRKSRC}/frontend/package.json
	@${REINPLACE_CMD} -e 's|	sudo npm install -g npm|	cd frontend \&\& env NODE_ENV=production npm install -D webpack-cli|g' ${WRKSRC}/Makefile
	@(cd ${WRKSRC} ; \
		./scripts/download-facenet.sh ; \
		./scripts/download-nasnet.sh ; \
		./scripts/download-nsfw.sh ; \
	)

patch-depends:
	${MKDIR} /portdistfiles/go
	chown -R nobody:nobody /portdistfiles/go

post-patch:
	@${REINPLACE_CMD} -e 's|graft v0.10.0|graft v0.5.1|g' ${WRKSRC}/go.mod
	@${REINPLACE_CMD} -e 's|graft v0.10.0 h1:HSpBUvm7O+jwsRIuDQlw80xW4xMXRFkOiVLtWaZCU2s=|graft v0.5.1 h1:wK1to5Q1ULsxKMOw9LmYbUlxFwKXiwotMjaaurPxz1w=|g' ${WRKSRC}/go.sum
	@${REINPLACE_CMD} -e 's|graft v0.10.0/go.mod h1:k6NJX3fCM/xzh5NtHky9USdgHTcz2vAvHp4c23I6UK4=|graft v0.5.1/go.mod h1:+qbkZFJnxKOKUXOjIWQW+W5Bw0KU3JZYhMvlF4Fvtl8=|g' ${WRKSRC}/go.sum

pre-build:
	${MKDIR} ${WRKSRC}/build
	${MKDIR} ${WRKSRC}/assets/static/build

	@( cd ${WRKSRC}/frontend; \
		export HOME=/tmp ; \
		npm install --yes -D webpack-cli@^6.0.1 ; \
	)

do-build:
	@( cd ${WRKSRC}/frontend; \
		env NODE_ENV=production npm run build ; \
		)
	@( cd ${WRKSRC} ; \
		${SETENV} ${MAKE_ENV} ${GO_ENV} ${GO_CMD} build -v ${_GO_TAGS} -ldflags \
	"-X main.version=${DISTVERSION:C/^...//}-${GH_TAGNAME:C/([0-9a-f]{7}).*/\1/}-${BUILD_OS}-${BUILD_ARCH}-DEBUG-build-${BUILD_DATE}" \
	-o ${WRKSRC}/photoprism ./cmd/photoprism/photoprism.go ; \
		)

do-install:
	${INSTALL_PROGRAM} ${WRKSRC}/photoprism ${STAGEDIR}${PREFIX}/bin
	${MKDIR} ${STAGEDIR}${PHOTOPRISM_DATA_DIR}
	${CP} -r ${WRKSRC}/assets ${STAGEDIR}${PHOTOPRISM_DATA_DIR}/assets

pre-install:
	${MKDIR} ${STAGEDIR}${PHOTOPRISM_DATA_DIR}

.include <bsd.port.mk>
