import { sensor } from '@kit.SensorServiceKit';
import { geoLocationManager } from '@kit.LocationKit';

const screenSize: number = 466

interface Location {
  lat: number
  long: number
}

const qiblaCoords: Location = { lat: 21.4224779, long: 39.8251832 }

@Entry
@Component
struct Index {
  @State azimuth: number = 0
  @State qiblaBearing: number = 0
  private timer1: number = 0
  @State location: Location = { lat: 0, long: 0 }

  async getCurrentLocation() {
    try {
      const requestInfo: geoLocationManager.CurrentLocationRequest = {
        priority: geoLocationManager.LocationRequestPriority.FIRST_FIX,
        scenario: geoLocationManager.LocationRequestScenario.UNSET,
        maxAccuracy: 100,
        timeoutMs: 10000
      };

      const location = await geoLocationManager.getCurrentLocation(requestInfo);
      this.location.lat = location.latitude
      this.location.long = location.longitude

    } catch (error) {
      console.error(JSON.stringify(error));
    }
  }

  onPageShow() {
    this.getCurrentLocation()
    this.timer1 = setInterval(() => {
      this.getCurrentLocation()
      this.qiblaBearing = this.greatCircleBearing(this.location, qiblaCoords)
    }, 5000)


    try {
      sensor.on(sensor.SensorId.ROTATION_VECTOR,
        (data: sensor.RotationVectorResponse) => {
          const x = data.x
          const y = data.y
          const z = data.z
          const w = data.w

          const siny_cosp = 2 * (w * z + x * y)
          const cosy_cosp = 1 - 2 * (y * y + z * z)
          const azimuthRad = Math.atan2(siny_cosp, cosy_cosp)
          const azimuthDeg = (azimuthRad * 180 / Math.PI + 360) % 360

          this.azimuth = azimuthDeg
          //this.azimuth = (this.azimuth + 1) % 360 // for testing, emulator does not support ROTATION_VECTOR data currently
        },
        { interval: 100 }
      );
    } catch (err) {
      console.error('Rotation sensor start error:', err);
    }

  }

  private greatCircleBearing(l1: Location, l2: Location): number {
    const toRad = (deg: number) => deg * Math.PI / 180;
    const fi1 = toRad(l1.lat);
    const fi2 = toRad(l2.lat);
    const delta = toRad(l2.long - l1.long);

    const x = Math.sin(delta) * Math.cos(fi2);
    const y = Math.cos(fi1) * Math.sin(fi2) -
      Math.sin(fi1) * Math.cos(fi2) * Math.cos(delta);

    const bearing = Math.atan2(x, y);
    return (bearing * 180 / Math.PI + 360) % 360;
  }

  private bearingDiff(a: number, b: number): number {
    const diff = Math.abs(a - b) % 360
    return diff > 180 ? 360 - diff : diff
  }

  build() {
    NavDestination() {

      Stack() {
        Rect()
          .width('100%')
          .height('100%')

        Image($r('app.media.compass'))
          .width(screenSize / 2)
          .height(screenSize / 2)
          .rotate({ angle: -this.azimuth })

        Image($r('app.media.qibla_icon'))
          .width(screenSize / 2)
          .height(screenSize / 2)
          .rotate({ angle: (this.qiblaBearing - this.azimuth + 360) % 360 })

        Image(
          this.bearingDiff(this.azimuth, this.qiblaBearing) <= 5 ? $r('app.media.compass_needle_green') :
            $r('app.media.compass_needle_red')
        )
      }
      .width('100%')
      .height('100%')

    }
    .hideTitleBar(true)

  }
}
