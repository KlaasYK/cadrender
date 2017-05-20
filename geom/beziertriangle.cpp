#include <geom/beziertriangle.h>

BezierTriangle::BezierTriangle(const QVector<QVector4D> &controlPoints) {
    Q_ASSERT(controlPoints.length() == NUM_CONTROL_POINTS);
    _controlPoints = controlPoints;
}

BezierTriangle::~BezierTriangle() {

}
